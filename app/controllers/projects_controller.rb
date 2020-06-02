require 'miga'
require 'miga/daemon'

class ProjectsController < ApplicationController
  before_action :set_project,
    only: [:destroy, :show, :search, :reference_datasets,
      :medoid_clade, :medoid_clade_as,
      :rdp_classify, :rdp_classify_as, :new_ncbi_download,
      :show_dataset, :result, :result_partial, :reference_dataset_result,
      :daemon_toggle, :new_reference, :create_reference]
  before_action :logged_in_user, only: [:result]
  before_action :admin_user,
    only: [:lair, :lair_toggle, :daemon_toggle,
      :daemon_start_all, :daemon_stop_all, :daemon_action_all]
  if Settings.user_projects
    before_action :logged_in_user, only: [:new, :create]
    before_action :correct_user_or_admin,
      only: [:destroy, :new_ncbi_download, :create_ncbi_download,
        :new_reference, :create_reference]
  else
    before_action :admin_user,
      only: [:new, :create, :destroy, :new_ncbi_download, :create_ncbi_download,
        :new_reference, :create_reference]
  end

  # Initiate (paginated) list of projects.
  def index
    @selection = :all
    if params[:private]
      @selection = :private
      @projects = Project.where(private: true, user: current_user)
            .paginate(page: params[:page])
    elsif params[:user_contributed]
      @selection = :'user-contributed'
      @projects = Project.where(official: false, private: false)
            .paginate(page: params[:page])
    elsif params[:type]
      @selection = params[:type].to_sym
      @projects = Project.where(private: false, official: true)
            .select { |i| !i.miga.nil? and i.miga.type.to_s == params[:type] }
            .paginate(page: params[:page])
    else
      @projects = Project.where(private: false, official: true)
            .paginate(page: params[:page])
    end
  end
  
  # Create an empty abstract project.
  def new
    @project = Project.new
  end
  
  # Loads a given project.
  def show
  end

  # Queries reference datasets in the project
  def search
    # Query
    @q       = params[:q]
    @query   = @q.split(/\s(?=(?:[^"]|"[^"]*")*$)/).map do |i|
      (i =~ /^(?:([A-Za-z_]+):)?"?(.*?)"?$/) ? [$2, $1] : [i, nil]
    end
    # Results
    return if (m = @project.miga).nil? or
              (r = m.result(:project_stats)).nil? or
              (db_file = r.file_path(:metadata_index)).nil?
    db = SQLite3::Database.new db_file
    @results = nil
    @query.each do |q|
      q[0] = q[0].downcase.gsub(/[^A-Za-z0-9\-]+/, " ")
      res = db.execute("select distinct(name) from metadata " +
              "where value like ? #{"and field=?" unless q[1].nil?}",
              ["% #{q[0]} %"] + (q[1].nil? ? [] : [q[1]])).flatten
      @results.nil? ? @results=res :
        @results.select!{ |i| res.include? i }
    end
    reference_datasets
  end
  
  # Loads (paginated) list of reference datasets in a project.
  def reference_datasets
    if @results.nil?
      @ref_datasets = @project.ref_datasets
    else
      @ref_datasets = @results
    end
    cur_page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 10).to_i
    @datasets = WillPaginate::Collection.create(
                        cur_page, per_page, @ref_datasets.size) do |pager|
      start = (cur_page - 1) * per_page
      pager.replace(@ref_datasets[start, per_page])
    end
  end
  
  # Loads a medoid clade for in-page display.
  def medoid_clade
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
    redirect_to root_url if @project.miga.nil?
    @ds_name = params[:ds_name]
    @result = @project.rdp_classify(@ds_name)
  end
  
  # Loads an RDP classification for asynchronous display.
  def rdp_classify_as
    rdp_classify
    render partial: 'rdp_classify',
      locals: { project: @project, ds_name: @ds_name, result: @result },
      layout: false
  end
  
  # Loads a given dataset in a project.
  def show_dataset
    @dataset_miga = @project.miga.dataset(params[:dataset])
    redirect_to root_url if @dataset_miga.nil?
  end
  
  # Create project.
  def create
    @user = User.find_by(id: params[:user_id])
    par = project_params
    par[:official] = false unless @user.admin?
    @project = @user.projects.create(par)
    if @project.save && !@project.miga.nil?
      [:name, :description, :comments, :type,
            :ani_p, :aai_p, :haai_p].each do |k|
        @project.miga.metadata[k] = params[k] unless
          params[k].nil? || params[k].empty?
      end
      @project.miga.save
      flash[:success] = 'Project created.'
      redirect_to @project
    else
      render 'new'
    end
  end
  
  # Destroys project.
  def destroy
    FileUtils.rm_rf @project.miga.path
    @project.destroy
    flash[:success] = 'Project deleted'
    redirect_to root_url
  end
  
  # Loads a result of a project.
  def result
    if p = @project && m = p.miga
      if res = m.result(params[:result])
        if file = res.data[:files][params[:file].to_sym]
          send_result(file, res)
          return
        end
      end
    end
    render nothing: true, status: 200, content_type: 'text/html'
  end

  # Displays the result as a partial for asynchronous loading
  def result_partial
    begin
      if params[:q_ds].nil?
        obj = @project
        proj = obj
        unless params[:r_ds].nil?
          obj = obj.miga.dataset(params[:r_ds])
          obj_miga = obj
        end
      else
        obj = QueryDataset.find(params[:q_ds])
      end
      obj_miga ||= obj.miga
      res = obj_miga.result(params[:result])
      render partial: 'shared/result',
        locals: { res: res, key: params[:result].to_sym, obj: obj, proj: proj },
        layout: false
    rescue
      render nothing: true, status: 200, content_type: 'text/html'
    end
  end

  # Loads a result from a reference dataset in a project.
  def reference_dataset_result
    if p = @project and m = p.miga
      if ds = m.dataset(params[:dataset]) and res = ds.result(params[:result])
        if file = res.data[:files][params[:file].to_sym]
          send_result(file, res)
          return
        end
      end
    end
    render nothing: true, status: 200, content_type: 'text/html'
  end

  # Initiates project for NCBI download.
  def new_ncbi_download
    show
  end
  
  # Launches an NCBI download in the background.
  def create_ncbi_download
    @project = Project.find(params[:project_id])
    if params[:species].nil? || params[:species].empty?
      flash[:danger] = 'Species name cannot be empty'
      redirect_to project_new_ncbi_download_url(@project)
      return
    end

    s = %i[complete chromosome scaffold contig].select { |i| params[i] }
    if @project.ncbi_download!(params[:species], s.compact)
      flash[:success] = 'Downloading reference genomes in the background...'
      redirect_to @project
    else
      render 'new_ncbi_download'
    end
  end

  # Admin daemons
  def lair
    require 'miga/lair'
    @projects = Project.all
    @lair = MiGA::Lair.new(Settings.miga_projects)
  end

  def lair_toggle
    require 'miga/lair'
    lair = MiGA::Lair.new(Settings.miga_projects)
    action = lair.active? ? :stop : :start
    lair.daemon(action)
    flash[:success] = "Daemon controller successful action: #{action}"
    sleep(1)
    redirect_to lair_url
  end

  def daemon_toggle
    daemon = MiGA::Daemon.new(@project.miga)
    action = daemon.active? ? :stop : :start
    daemon.daemon(action)
    flash[:success] = "Daemon successful action: #{action}"
    sleep(1)
    redirect_to lair_url
  end

  def daemon_action_all(action)
    require 'miga/lair'
    lair = MiGA::Lair.new(Settings.miga_projects)
    lair.each_daemon { |d| d.daemon(action) }
    flash[:success] = "Signal sent to all daemons: #{action}"
    sleep(1)
    redirect_to lair_url
  end

  def daemon_start_all
    daemon_action_all(:start)
  end

  def daemon_stop_all
    daemon_action_all(:stop)
  end

  def new_reference
    @query_dataset = QueryDataset.new
    @reference = true
    render 'query_datasets/new'
  end

  def create_reference
  end

  #Fang retuen how many data has completed
  def progress
    id = params[:id]
    project = Project.find(id)
    status = project.miga.datasets.map(&:status)
    logger.info ">>>>>> Look at me <<<<<<<<<<<<<<<<<"
    logger.info ">>>>>> Look at me <<<<<<<<<<<<<<<<<"
    logger.info ">>>>>> Look at me <<<<<<<<<<<<<<<<<"
    logger.info ">>>>>> Look at me <<<<<<<<<<<<<<<<<"
    incomplete = status.count(:incomplete)
    total = status.size
    inactive = status.count(:inactive)
    complete = (total - incomplete) - inactive
    p_incomplete = (incomplete.to_f * 100.0)/total
    p_complete = 100.0 - p_incomplete

    p_complete = p_complete.round(2)
   # status = project.datasets.map(&:status)
    logger.info ".. hahaha ... got incomplete: #{incomplete} , ina: #{inactive}, comp: #{complete} "
   
    #reading outputfile
    f = File.expand_path("daemon/MiGA\:#{project.miga.name}.output", project.miga.path)
    last_line = `tail -n 1 #{f}`
    logger.info("last 1 : " + last_line)
    last_five_lines = `tail -n 5 #{f}`
    logger.info ("last 5 : " + last_five_lines)
    #daemon acitve?
    active = project.daemon_active?
    
    #put on the map 
    @map_p = Hash.new
    @map_p[:total] = total
    @map_p[:inactive] = inactive
    @map_p[:incomplete] = incomplete
    @map_p[:complete] = complete
    @map_p[:percentage] = p_complete
    @map_p[:last_line] = last_line
    @map_p[:last_five_lines] = last_five_lines
    @map_p[:active] = active
    respond_to do |format|
      format.html
      format.json {render json: @map_p}
    end 
  end


  private

  def set_project
    id = params[:id]
    id ||= params[:project_id]
    qry = id =~ /\A\d+\z/ ? :id : :path
    @project = Project.find_by(qry => id)
  end

  def project_params
    params.require(:project).permit(:path, :private, :official)
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
      render template: 'shared/result_dir'
    else
      case File.extname(file)
      when '.pdf'
        send_file(f, filename: file, disposition: 'inline',
          type: 'application/pdf', x_sendfile: true)
      when '.html'
        send_file(f, filename: file, disposition: 'inline',
          type: 'text/html', x_sendfile: true)
      else
        send_file(f, filename: file, disposition: 'inline',
          type: 'raw/text', x_sendfile: true)
      end
    end
  end

  # Confirms the correct user
  def correct_user_or_admin
    @user = @project.user
    return true if @user.nil?
    redirect_to(root_url) if current_user.nil? ||
      !(current_user?(@user) || current_user.admin?)
  end
end
