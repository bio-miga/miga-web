class QueryDataset < ActiveRecord::Base
  belongs_to :user
  belongs_to :project
  default_scope -> { order(created_at: :desc) }
  mount_uploader :input_file, InputFileUploader
  mount_uploader :input_file_2, InputFileUploader
  attr_accessor :miga_obj
  validates :user_id, presence: true
  validates :project_id, presence: true
  validates :name, presence: true, miga_name: true
  validates :input_file, presence: true
  validates :input_type, presence: true,
    inclusion: { in: %w(raw_reads trimmed_fasta assembly) }
  before_save :create_miga_dataset

  def self.by_user_and_project(user, project)
    QueryDataset.where(["user_id=? and project_id=?", user.id, project.id])
  end

  def self.complete_new_by_user(user)
    QueryDataset.where(["user_id=? and complete_new=?", user.id, true])
  end

  def self.unknown_ready_by_user(user)
    QueryDataset.where(["user_id=? and ready=?", user.id, false])
  end

  # Returns the MiGA name of the dataset
  def miga_name
    "qG_#{name}_u#{user_id}"
  end

  # Returns the MiGA dataset object
  def miga
    load_miga_dataset
    miga_obj
  end

  # Checks if it's ready
  def ready?
    return true if complete
    if miga.nil? or miga.done_preprocessing?
      update_attribute(:complete, true)
      update_attribute(:complete_new, true)
    end
    complete
  end

  # Sets the "new" flag off
  def complete_seen!
    update_attribute(:complete_new, false) if complete_new
  end

  # Returns the running log of the task (if any)
  def job_log(task)
    f = File.expand_path("daemon/#{task}/#{miga.name}.log", project.miga.path)
    return "" unless File.exist? f
    File.read(f)
  end

  private

    def create_miga_dataset
      return if MiGA::Dataset.exist? project.miga, miga_name
      MiGA::Dataset.new(project.miga, miga_name, false,
        {user: user_id, type: :genome})
      project.miga.add_dataset(miga.name)
      case input_type.to_sym
      when :raw_reads
        # ToDo: Add support for .gz!
        FileUtils.copy(input_file.path,
          File.expand_path("data/01.raw_reads/#{miga_name}.1.fastq",
            project.miga.path))
        FileUtils.copy(input_file_2.path,
          File.expand_path("data/01.raw_reads/#{miga_name}.2.fastq",
            project.miga.path)) unless input_file_2.path.nil?
        f = File.open(
          File.expand_path("data/01.raw_reads/#{miga_name}.done",
            project.miga.path), "w")
        f.puts Time.now.to_s
        f.close
        miga.add_result :raw_reads
      when :assembly
        FileUtils.copy(input_file.path,
          File.expand_path("data/05.assembly/#{miga_name}.LargeContigs.fna",
            project.miga.path))
        f = File.open(
          File.expand_path("data/05.assembly/#{miga_name}.done",
            project.miga.path), "w")
        f.puts Time.now.to_s
        f.close
        miga.add_result :assembly
      end
      # Empty input file
      f = File.open(input_file.path, "r")
      f.print ""
      f.close
    end
      
    def load_miga_dataset
      self.miga_obj = project.miga.dataset(miga_name) if
        miga_obj.nil? and MiGA::Dataset.exist?(project.miga, miga_name)
    end

end
