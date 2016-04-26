class QueryDatasetsController < ApplicationController
  before_action :logged_in_user, only: [:index, :new, :create, :show, :destroy,
    :result]
  
  before_action :correct_user_or_admin, only: [:show, :destroy, :result]

  def index
    # Find query datasets
    if params[:project_id]
      @project = Project.find(params[:project_id])
      qd = params[:all] ?
        @project.query_datasets.all :
        QueryDataset.by_user_and_project(current_user, @project)
    else
      @project = nil
      qd = params[:all] ?
        QueryDataset.all :
        current_user.query_datasets
    end
    @all_qd = qd.count
    params[:ready] ||= false
    if params[:ready]=="yes"
      qd = qd.select{ |qd| qd.ready? }
      @ready_qd = qd.count
      @running_qd = @all_qd - @ready_qd
    elsif params[:ready]=="no"
      qd = qd.select{ |qd| not qd.ready? }
      @running_qd = qd.count
      @ready_qd = @all_qd - @running_qd
    else
      @ready_qd = qd.select{ |qd| qd.ready? }.count
      @running_qd = @all_qd - @ready_qd
    end
    # Paginate
    cur_page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 30).to_i
    @query_datasets = WillPaginate::Collection.create(cur_page, per_page,
                            qd.size) do |pager|
      start = (cur_page-1)*per_page
      pager.replace(qd[start, per_page])
    end
  end
   
  def new
    @project = Project.find_by(id: params[:project_id])
    if @project.nil?
      redirect_to projects_path
    else
      @query_dataset = QueryDataset.new
    end
  end

  def show
    @query_dataset = QueryDataset.find(params[:id])
  end

  def create
    @project = Project.find_by(id: query_dataset_params[:project_id])
    if @project.nil?
      redirect_to root_url
    else
      @query_dataset = @project.query_datasets.create(query_dataset_params)
      flash[:success] = "It's saved" if @query_dataset.save!
      if @query_dataset.save and not @query_dataset.miga.nil?
        [:description,:comments,:type].each do |k|
          @query_dataset.miga.metadata[k] = params[k] unless
            params[k].nil? or params[k].empty?
        end
        @query_dataset.miga.save
        flash[:success] = "Query dataset created."
        redirect_to @query_dataset
      else
        params[:project_id] = query_dataset_params[:project_id]
        flash[:danger] = "Query dataset couldn't be saved."
        render "new"
      end
    end
  end

  def destroy
    qd = QueryDataset.find(params[:id])
    p = qd.project
    u = qd.user
    p.miga.unlink_dataset qd.miga.name
    qd.miga.remove!
    qd.destroy
    redirect_to u
  end

  def result
    if qd = QueryDataset.find(params[:id]) and m = qd.miga
      if res = m.result(params[:result])
        if file = res.data[:files][params[:file].to_sym]
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
            case File.extname(f)
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
          return
        end
      end
    end
    render :nothing => true, :status => 200, :content_type => "text/html"
  end

  private

    def query_dataset_params
      params.require(:query_dataset).permit(
        :name, :user_id, :project_id, :input_file, :input_file_2, :input_type)
    end
      
    # Confirms the correct user
    def correct_user_or_admin
      @user = QueryDataset.find(params[:id]).user
      redirect_to(root_url) unless current_user?(@user) or current_user.admin?
    end
end
