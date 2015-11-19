require "miga/daemon"
class Project < ActiveRecord::Base
   belongs_to :user
   has_many :query_datasets, dependent: :destroy
   attr_accessor :miga_obj, :code
   validates :user_id, presence: true
   validates :path, presence: true, miga_name: true,
      uniqueness: { case_sensitive: false }
   before_save :create_miga_project

   def path_name
      path.gsub(/_/," ").capitalize
   end

   def miga
      load_miga_project
      miga_obj
   end

   def daemon_last_alive
      MiGA::Daemon.last_alive miga
   end

   def daemon_active?
      return false if daemon_last_alive.nil?
      daemon_last_alive > 1.hour.ago
   end

   def ref_datasets
      return [] if miga.nil?
      miga.metadata[:datasets].reject{ |n| n =~ /^qG_.*_u\d+$/ }
   end

   def code
      @code ||= path.gsub(/^(.)(?:.*_)?(.).*/,"\\1\\2")
   end

   private

      def full_path
	 File.expand_path(path, ENV["MIGA_PROJECTS"])
      end

      def create_miga_project
	 project = MiGA::Project.new full_path
	 project.metadata[:user] = user.id
	 project.save
      end

      def load_miga_project
	 @miga_obj ||= MiGA::Project.load(full_path)
      end
end
