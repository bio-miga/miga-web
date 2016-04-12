require "miga/daemon"
class Project < ActiveRecord::Base
   belongs_to :user
   has_many :query_datasets, dependent: :destroy
   attr_accessor :miga_obj, :code
   validates :user_id, presence: true
   validates :path, presence: true, miga_name: true,
      uniqueness: { case_sensitive: false }
   before_save :create_miga_project
   default_scope -> { order(path: :asc) }

   def path_name
      path.gsub(/_/," ").capitalize
   end

   def miga
      load_miga_project
      miga_obj
   end

   def daemon_last_alive
      return nil if miga.nil?
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

   def code_base_color
      sprintf("%06x", (XXhash.xxh32(path,6) % (16**6)))
   end
   
   def code_color
      c = Color::RGB.by_hex(code_base_color).to_hsl
      c.luminosity = 40 + c.luminosity/4
      c.saturation = 40 + c.saturation/4
      c.css_hsl
   end

   def code_light_color
      c = Color::RGB.by_hex(code_base_color).to_hsl
      c.luminosity = 90 + c.luminosity/10
      c.saturation = 40 + c.saturation/4
      c.css_hsl
   end

   def dataset_counts(user)
      qd = QueryDataset.by_user_and_project(user, self)
      o = {ref: ref_datasets.count}
      o[:qry] = qd.count
      o[:qry_yes] = qd.select{ |qd| qd.ready? }.count
      o[:qry_no]  = o[:qry] - o[:qry_yes]
      o
   end
   
   def ncbi_download!(species, codes)
      Spawnling.new(argv: "miga-clades-spawn -#{path_name}-") do
	 require "miga/remote_dataset"
	 url = "http://www.ncbi.nlm.nih.gov/genomes/Genome2BE/genome2srv.cgi?" +
	    "action=download&orgn=#{URI::encode(species)}[orgn]&" +
	    "status=#{codes}&report=proks&group=--%20All%20Prokaryotes" +
	    "%20--&subgroup=--%20All%20Prokaryotes%20--&format="
	 g = 0
	 open(url) do |th|
	    th.each_line do |ln|
	       next if ln =~ /^#/
	       ln.chomp!
	       r = ln.split "\t"
	       entries = r[10].split("; ").map{ |e| e.gsub(/.*:/,"").gsub(/\/.*/,"") }.join(",")
	       name = entries.miga_name[0,50]
	       unless miga.metadata[:datasets].include? name
		  rd = MiGA::RemoteDataset.new(entries, :nuccore, :ncbi)
		  d = rd.save_to(miga, name, true, {type: :genome})
		  g += 1
	       end
	    end
	 end
	 logger.info("Project #{id}: Downloaded #{g} reference genomes.")
      end
      true
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
