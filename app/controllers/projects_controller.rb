class ProjectsController < ApplicationController
  before_action :logged_in_user, only: [:new, :create, :destroy, :show, :result,
    :reference_datasets, :show_dataset, :reference_dataset_result,
    :medoid_clade, :medoid_clade_as, :rdp_classify, :rdp_classify_as]
  
  before_action :admin_user, only: [:new, :create, :destroy, :new_ncbi_download,
    :create_ncbi_download, :start_daemon, :stop_daemon]

  # Initiate (paginated) list of projects.
  def index
    @projects = Project.paginate(page: params[:page])
  end
  
  # Create an empty abstract project.
  def new
    @project = Project.new
  end
  
  # Loads a given project.
  def show
    @project = Project.find(params[:id])
  end
  
  # Loads (paginated) list of reference datasets in a project.
  def reference_datasets
    @project = Project.find(params[:project_id])
    cur_page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 30).to_i
    @ref_datasets = @project.ref_datasets
    @datasets = WillPaginate::Collection.create(
                        cur_page, per_page, @ref_datasets.size) do |pager|
      start = (cur_page - 1) * per_page
      pager.replace(@ref_datasets[start, per_page])
    end
  end
  
  # Loads a medoid clade for in-page display.
  def medoid_clade
    @project = Project.find(params[:project_id])
    redirect_to root_url if @project.miga.nil?
    @metric = params[:metric].to_sym
    @result = @project.miga.add_result(
      @metric==:AAI ? :clade_finding : :subclades, false)
    @clade = params[:clade]
    @clade_name = "#{@metric} clade #{@clade}"
    @clade_miga = @clade.split("-").
      map{ |i| "miga-project.sc-#{i}" }.join("/")
  end
  
  # Loads a medoid clade for asynchronous display.
  def medoid_clade_as
    medoid_clade
    render partial: "medoid_clade",
      locals: { project: @project, result: @result, metric: @metric,
        target: @clade, root: File.expand_path(@clade_miga, @result.dir),
	root_name: @clade },
      layout: false
  end

  # Loads an RDP classification for in-page display.
  def rdp_classify
    @project = Project.find(params[:project_id])
    redirect_to root_url if @project.miga.nil?
    @ds_name = params[:ds_name]
    @result = @project.rdp_classify(@ds_name)
  end
  
  # Loads an RDP classification for asynchronous display.
  def rdp_classify_as
    rdp_classify
    render partial: "rdp_classify",
      locals: { project: @project, ds_name: @ds_name, result: @result },
      layout: false
  end
  
  # Loads a given dataset in a project.
  def show_dataset
    @project = Project.find(params[:id])
    @dataset_miga = @project.miga.dataset(params[:dataset])
    redirect_to root_url if @dataset_miga.nil? or not @dataset_miga.is_ref?
  end
  
  # Create project.
  def create
    @user = User.find_by(id: params[:user_id])
    @project = @user.projects.create(project_params)
    if @project.save and not @project.miga.nil?
      [:name,:description,:comments,:type].each do |k|
        @project.miga.metadata[k] = params[k] unless
          params[k].nil? or params[k].empty?
      end
      @project.miga.save
      flash[:success] = "Project created."
      redirect_to @project
    else
	 render "new"
    end
  end
  
  # Destroys project.
  def destroy
    project = Project.find(params[:id])
    FileUtils.rm_rf project.miga.path
    project.destroy
    flash[:success] = "Project deleted"
    redirect_to root_url
  end
  
  # Loads a result of a project.
  def result
    if p = Project.find(params[:id]) and m = p.miga
      if res = m.result(params[:result])
        if file = res.data[:files][params[:file].to_sym]
          send_result(file, res)
          return
        end
      end
    end
    render :nothing => true, :status => 200, :content_type => "text/html"
  end

  # Loads a result from a reference dataset in a project.
  def reference_dataset_result
    if p = Project.find(params[:id]) and m = p.miga
      if ds = m.dataset(params[:dataset]) and res = ds.result(params[:result])
        if file = res.data[:files][params[:file].to_sym]
          send_result(file, res)
          return
        end
      end
    end
    render :nothing => true, :status => 200, :content_type => "text/html"
  end

  # Initiates project for NCBI download.
  def new_ncbi_download
    show
  end
  
  # Launches an NCBI download in the background.
  def create_ncbi_download
    @project = Project.find(params[:project_id])
    species = params[:species] || ""
    codes = ""
    codes += "50|" if params[:complete]
    codes += "40|" if params[:chromosome]
      
    if codes.empty? or species.empty?
      flash[:danger] = "Nothing to do, " +
        "please set at least one status to download." if codes.empty?
      flash[:danger] = "Nothing to do, " +
        "please specify a species name." if species.empty?
      render "new_ncbi_download"
    else
      if @project.ncbi_download!(species, codes)
        flash[:success] = "Downloading reference genomes in the background..."
        redirect_to @project
      else
        render "new_ncbi_download"
      end
    end
  end
  
  # Launch daemon in the background.
  def start_daemon
    require "miga/daemon"
    @project = Project.find(params[:id])
    return if @project.daemon_active?
    daemon = MiGA::Daemon.new( @project.miga )
    f = File.open(File.expand_path("daemon/alive", @project.miga.path), "w")
    f.print Time.now.to_s
    f.close
    Spawnling.new { daemon.start }
    redirect_to @project
  end
  
  # Stops a daemon running in the background.
  def stop_daemon
    require "miga/daemon"
    @project = Project.find(params[:id])
    return unless @project.daemon_active?
    daemon = MiGA::Daemon.new( @project.miga )
    File.unlink(File.expand_path("daemon/alive", @project.miga.path))
    Spawnling.new { daemon.stop }
    redirect_to @project
  end

  private

    def project_params
      params.require(:project).permit(:path)
    end

    def send_result(file, res)
      f = File.expand_path(file, res.dir)
      if Dir.exist? f and params[:f] and not params[:f]=~/\//
        f = File.expand_path(params[:f], f)
        file = params[:f]
      end
      if Dir.exist? f
        @path = f
        @file = file
        @res = res
        render template: "shared/result_dir"
      else
        case File.extname(file)
        when ".pdf"
          send_file(f, filename:file, disposition:"inline",
            type:"application/pdf", x_sendfile:true)
        when ".html"
          send_file(f, filename:file, disposition:"inline",
            type:"text/html", x_sendfile:true)
        else
          send_file(f, filename:file, disposition:"inline",
            type:"raw/text", x_sendfile:true)
        end
      end
    end
end
