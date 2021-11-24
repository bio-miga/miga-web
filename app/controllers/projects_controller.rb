require 'miga'
require 'miga/daemon'

class ProjectsController < ApplicationController
  before_action :set_project,
    only: [:destroy, :show, :search, :reference_datasets,
      :medoid_clade, :medoid_clade_as,
      :rdp_classify, :rdp_classify_as,
      :new_ncbi_download, :create_ncbi_download,
      :show_dataset, :result, :result_partial, :reference_dataset_result,
      :daemon_toggle, :new_reference, :create_reference, :progress,
      :delete_ref_dataset]
  before_action :logged_in_user, only: [:result]
  before_action :admin_user,
    only: [:lair, :lair_toggle, :daemon_toggle,
      :daemon_start_all, :daemon_stop_all, :daemon_action_all,
      :discovery, :link, :get_db, :launch_get_db]
  if Settings.user_projects
    # Servers with user-owned projects
    before_action(
      Settings.user_create_projects ? :logged_in_user : :admin_user,
      only: [:new, :create]
    )
    before_action :correct_user_or_admin,
      only: [:destroy, :new_ncbi_download, :create_ncbi_download,
        :new_reference, :create_reference, :progress, :delete_ref_dataset]
  else
    # Servers without user-owned projects
    before_action :admin_user,
      only: [:new, :create, :destroy, :new_ncbi_download, :create_ncbi_download,
        :new_reference, :create_reference, :progress, :delete_ref_dataset]
  end

  # Initiate (paginated) list of projects.
  def index
    @selection = :public
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
  
  # GET /project/new
  # Create an empty abstract project
  def new
    @project = Project.new
    @refdb = Project.where(reference: true)
  end

  # GET /project/1
  # Loads a given project
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
    @clade_miga = @clade.split('-').
      map{ |i| "miga-project.sc-#{i}" }.join('/')
  end
  
  # Loads a medoid clade for asynchronous display.
  def medoid_clade_as
    medoid_clade
    render partial: 'medoid_clade',
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

  # Create project
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
      if params[:reference_db]
        if Settings.miga_exec_projects
          @project.miga.metadata[:ref_project] =
            File.join(Settings.miga_exec_projects, params[:reference_db])
        else
          ref = Project.find_by(path: params[:reference_db])
          ref_path = ref.miga.path if ref && ref.miga
          @project.miga.metadata[:ref_project] = ref_path
        end
      end
      @project.miga.save
      flash[:success] = 'Project created'
      redirect_to @project
    else
      render 'new'
    end
  end
  
  # Destroys project
  def destroy
    FileUtils.rm_rf @project.miga.path
    @project.destroy
    flash[:success] = 'Project deleted'
    redirect_to root_url
  end
  
  # Loads a result of a project
  def result
    if @project && @project.miga &&
          (result = @project.miga.result(params[:result])) &&
          (file = result.data[:files][params[:file].to_sym])
      send_result(file, result)
    else
      head :ok, content_type: 'text/html'
    end
  end

  # Displays the result as a partial for asynchronous loading
  def result_partial
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
  #rescue
  #  head :ok, content_type: 'text/html'
  end

  # Loads a result from a reference dataset in a project
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

  # Initiates project for NCBI download
  def new_ncbi_download
    show
  end
  
  # Launches an NCBI download in the background
  def create_ncbi_download
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

  # List remote databases to download
  def get_db
    manif = Project.miga_online_manif
    @downloadable = manif[:databases].map do |name, i|
      local = Project.find_by(path: name)
      local_v = (local.miga.metadata[:release] || 'unknown') if local && local.miga
      latest = i[:versions][i[:latest].to_sym]
      file = File.join(Settings.miga_projects, latest[:path])
      downloading = File.size(file) * 100 / latest[:size] if File.exist?(file)
      i.merge(name: name, local: local_v, downloading: downloading)
    end
  end

  # Download or update the database in the background
  def launch_get_db
    name = params[:name]
    version = params[:version]
    Thread.new do
      require 'miga/cli'

      # Get current registered version
      project = Project.find_by(path: name)
      if project && project.miga
        project.miga.metadata[:release] =
          "#{project.miga.metadata[:release]} (currently updating)"
        project.miga.save
      end

      # Download
      error =
        MiGA::Cli.new([
          'get_db', '-n', name, '--db-version', version,
          '--local-dir', Settings.miga_projects, '--no-progress'
        ]).launch
      raise(error) if error.is_a? Exception

      # Register in the database
      project ||= current_user.projects.create(path: name)
      project.update(reference: true)
      f = File.join(Settings.miga_projects, "#{name}_#{version}.tar.gz")
      File.unlink(f) if File.exist? f
      ActiveRecord::Base.connection.close
    end

    sleep(10) # <- Hopefully this is enough to start the download
    flash[:success] = 'Downloading database in the background'
    redirect_to get_db_path
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
  end

  def create_reference
    cmd = params.require(:query_dataset).permit(
      :name, :input_type, :input_file, :input_file_2
    )
    cmd.merge! params.permit(:type, :comments, :description)
    back_to = project_reference_datasets_path(@project)
    errors = nil
    success = []

    case cmd[:input_type]
    when 'assembly'
      max_upload_files = current_user.nil? ? 1 : Settings.max_user_upload
      if params[:asm_file].size > max_upload_files
        errors = 'Too many files uploaded'
      else
        params[:asm_file].each_with_index do |file, idx|
          errors = @project.create_miga_dataset(
            cmd.merge({
              name: params[:asm_name][idx],
              description: params[:asm_description][idx],
              comments: params[:asm_comments][idx]
            }),
            file.path
          ) and break
          success << params[:asm_name][idx]
        end
      end
    else
      errors = @project.create_miga_dataset(
        cmd, cmd[:input_file].path,
        (cmd[:input_file_2].path if cmd[:input_file_2])
      )
      success << cmd[:name] unless errors
    end

    if success.size == 1
      flash[:success] = "The dataset has been registered: #{success.first}"
      back_to = reference_dataset_path(@project, success.first)
    elsif success.size > 1
      flash[:success] = "#{success.size} datasets registered successfully"
    end

    if errors
      flash[:danger] = errors
      redirect_to project_new_reference_path
    else
      redirect_to back_to
    end
  end

  # GET /projects/:id/progress
  def progress
    ref_ds = @project.miga.dataset_names.select { |i| i !~ /^qG_/ }
    status = ref_ds.sample(100).map do |i|
      @project.miga.dataset(i).status
    end
    incomplete = status.count(:incomplete)
    total = status.size
    inactive = status.count(:inactive)
    complete = (total - incomplete) - inactive
    p_incomplete = (incomplete.to_f * 100.0)/total
    p_complete = 100.0 - p_incomplete

    p_complete = p_complete.round(2)
   
    # reading output file
    f = File.join(
      @project.miga.path, 'daemon', "MiGA:#{@project.miga.name}.output"
    )
    if File.exists?(f)
      last_five_lines = File.readlines(f).pop(5)
      last_line = last_five_lines.last
      last_five_lines = last_five_lines.join('')
      mtime = File.mtime(f).to_s
    else
      last_five_lines = nil
      last_line = nil
      mtime = nil
    end

    # is the daemon active?
    active = @project.daemon_active?
    
    # put on the map 
    @map_p = {
      total: total,
      inactive: inactive,
      incomplete: incomplete,
      complete: complete,
      percentage: p_complete,
      last_line: last_line,
      last_five_lines: last_five_lines,
      mtime: mtime,
      active: active
    }
    respond_to do |format|
      format.html
      format.json { render json: @map_p }
    end 
  end

  # GET /project_discovery
  def discovery
    require 'miga/lair'
    require 'pathname'

    lair = MiGA::Lair.new(Settings.miga_projects)
    @registered = Project.all.pluck(:official, :path, :user_id).map do |i|
      i[0] ? i[1] : File.join('user-contributed', i[2].to_s, i[1])
    end

    @existing = []
    data = Pathname.new(Settings.miga_projects)
    lair.each_daemon do |daemon|
      next if daemon.is_a? MiGA::Lair
      path = Pathname.new(daemon.project.path).relative_path_from(data)
      @existing << path.to_s
    end

    @unregistered = (@existing - @registered).map do |i|
      if i =~ /^[A-Za-z0-9_]+$/
        { path: i, type: :official }
      elsif i =~ /^user-contributed\/(\d+)\/([A-Za-z0-9_]+)$/
        user = User.find_by(id: $1)
        { path: $2, type: (user ? :user : :bad_user), user: user }
      else
        { path: i, type: :incompatible }
      end
    end
  end

  # GET /project_link
  def link
    par = params.permit([:path, :private, :official])
    @user = params[:user] ? User.find(params[:user]) : current_user
    @project = @user.projects.create(par)
    if @project.save && !@project.miga.nil?
      if params[:reference] == 'true'
        @project.update(reference: true)
        flash[:success] = 'Project successfully linked as Reference Database'
        redirect_to @project
      else
        flash[:success] = 'Project successfully linked'
        redirect_to @project
      end
    else
      flash[:danger] = 'An unexpected error occurred while linking project'
      redirect_to project_discovery_path
    end
  end

  # DELETE /project/:id/delete_ref_dataset
  def delete_ref_dataset
    dataset_name = params[:name]
    logger.info('dataset name is: ' + dataset_name)
    dataset = @project.miga.dataset(dataset_name)
    if dataset.nil?
      flash[:danger] = "Dataset #{dataset_name} does not exist"
    else
      @project.miga.unlink_dataset(dataset_name)
      dataset.remove!
      flash[:success] = "Dataset #{dataset_name} has been removed successfully"
    end
    redirect_to project_reference_datasets_path(@project)
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
