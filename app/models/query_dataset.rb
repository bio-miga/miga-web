class QueryDataset < ApplicationRecord
  belongs_to :user
  belongs_to :project
  default_scope -> { order(created_at: :desc) }
  mount_uploader :input_file, InputFileUploader
  mount_uploader :input_file_2, InputFileUploader
  attr_accessor :miga_obj
  validates :user_id, presence: true
  validates :project_id, presence: true
  validates :name, presence: true, miga_name: true,
    uniqueness: { scope: [:user, :project] }
  validates :input_file, presence: true
  validates :input_type, presence: true,
    inclusion: { in: %w(raw_reads trimmed_fasta assembly) }
  before_save :create_miga_dataset

  def self.by_user_and_project(user, project)
    QueryDataset.where(["user_id=? and project_id=?", user.nil? ? 0 : user.id, project.id])
  end

  def self.complete_new_by_user(user)
    QueryDataset.where(["user_id=? and complete_new=?", user.nil? ? 0 : user.id, true])
  end

  def self.unknown_ready_by_user(user)
    QueryDataset.where(["user_id=? and ready=?", user.nil? ? 0 : user.id, false])
  end

  # Generate a random new accession number
  def self.new_acc
    "M:" + SecureRandom.urlsafe_base64(5).upcase.tap{ |i| i[3]="_" }
  end

  def to_param
    self.update(acc:QueryDataset.new_acc) if self.acc.nil?
    self.acc
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
  
  # Always returns +false+.
  def is_ref? ; false ; end

  # Checks if it's ready
  def ready?
    return true if complete
    return false if miga.nil?
    if !miga.is_active? or miga.done_preprocessing?
      update_attribute(:complete, true)
      update_attribute(:complete_new, true)
    end
    complete
  end

  # Checks if MyTaxa scan is required for the dataset.
  def run_mytaxa_scan?
    return false if miga.nil?
    return false if miga.is_multi?
    !!(miga.metadata[:run_mytaxa_scan] || !miga.result(:mytaxa_scan).nil?)
  end

  # Tells MiGA to process MyTaxa scan for the dataset.
  def run_mytaxa_scan!
    return if run_mytaxa_scan?
    miga.metadata[:run_mytaxa_scan] = true
    miga.save
    update_attribute(:complete, false) if complete
    update_attribute(:complete_new, false) if complete_new
  end

  # Checks if Distances is not scheduled yet.
  def run_distances?
    return false if miga.nil?
    !(miga.result(:distances).nil?)
  end

  def run_distances!
    return unless run_distances?
    miga.result(:distances).remove!
    update_attribute(:complete, false) if complete
    update_attribute(:complete_new, false) if complete_new
  end

  # Sets the "new" flag off
  def complete_seen!
    update_attribute(:complete_new, false) if complete_new
  end

  # Returns the running log of the task (if any)
  def job_log(_task)
    f = File.expand_path("daemon/d/#{miga.name}.log", project.miga.path)
    return '' unless File.exist? f
    File.read(f).encode('UTF-8', 'binary',
      invalid: :replace, undef: :replace, replace: '?')
  end

  # Registers parameters in the MiGA object
  def save_in_miga(par)
    return false if miga.nil?
    [:description, :comments, :type].each do |k|
      next if par[k].nil? or par[k].empty?
      miga.metadata[k] = par[k]
    end
    miga.save
    true
  end

  private

    def create_miga_dataset
      return if MiGA::Dataset.exist?(project.miga, miga_name)
      f = { 1=>input_file, 2=>input_file_2 }
      t = input_type.to_sym
      MiGA::Dataset.new(project.miga, miga_name, false,
        { user: user_id, type: :genome })
      project.miga.add_dataset(miga_name)
      return unless MiGA::Dataset.RESULT_DIRS.keys.include? t
      r_base = File.join(project.miga.path, 'data',
        MiGA::Dataset.RESULT_DIRS[input_type.to_sym], miga_name)
      
      case t
      when :raw_reads
        copy_to_miga(f[1], "#{r_base}.1.fastq")
        copy_to_miga(f[2], "#{r_base}.2.fastq") unless f[2].path.nil?
      when :trimmed_fasta
        if f[2].path.nil?
          copy_to_miga(f[1], "#{r_base}.SingleReads.fa")
        else
          copy_to_miga(f[1], "#{r_base}.1.fasta")
          copy_to_miga(f[2], "#{r_base}.2.fasta")
        end
      when :assembly
        copy_to_miga(f[1], "#{r_base}.LargeContigs.fna")
      else
        return
      end
      File.open("#{r_base}.done", "w") { |fh| fh.puts Time.now.to_s }
      miga.add_result t
    ensure
      # Empty input files
      f ||= {}
      f.values.each do |i|
        File.open(i.path, "r"){ |fh| fh.print "" } unless i.path.nil?
      end
    end
 
    def load_miga_dataset
      self.miga_obj = project.miga.dataset(miga_name) if
        miga_obj.nil? and MiGA::Dataset.exist?(project.miga, miga_name)
    end

    def copy_to_miga(input, output)
      output += ".gz" if input.filename =~ /\.gz\z/
      FileUtils.copy(input.path, output)
    end

end
