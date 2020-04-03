class QueryDatasetsController < ApplicationController
  include ActionView::Helpers::TextHelper
  before_action :logged_in_user, only: [:index, :destroy]
  before_action :set_query_dataset,
    only: [:show, :destroy, :result, :run_mytaxa_scan, :run_distances,
      :mark_unread]
  before_action :correct_user_or_admin,
    only: [:show, :destroy, :result, :run_mytaxa_scan, :run_distances,
      :mark_unread]

  def index
    # Find query datasets
    qd = list_query_datasets
    # Paginate
    cur_page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 10).to_i
    @query_datasets = WillPaginate::Collection.create(cur_page, per_page,
                            qd.size) do |pager|
      start = (cur_page-1)*per_page
      pager.replace(qd[start, per_page])
    end
  end
   
  def new
    @project ||= Project.find_by(id: params[:project_id])
    if @project.nil?
      redirect_to projects_path
    else
      @query_dataset = QueryDataset.new
    end
  end

  def show
    @query_dataset.complete_seen!
  end

  def create
    @project = Project.find_by(id: query_dataset_params[:project_id])
    if @project.nil?
      redirect_to projects_url
    else
      par = query_dataset_params
      if par[:input_type] == 'assembly'
        saved_cnt = 0
        @bad_objects = []
        max_upload_files = current_user.nil? ? 1: Settings.max_user_upload
        if params[:asm_file].size > max_upload_files
          flash[:danger] = 'Too many files uploaded'
          redirect_to new_query_dataset_path(project_id: @project.id)
        else
          params[:asm_file].each_with_index do |file, idx|
            par[:name] = params[:asm_name][idx]
            par[:name] += '_' + SecureRandom.hex(4) if current_user.nil?
            par[:input_file] = file
            @query_dataset = @project.query_datasets.create(par)
            if @query_dataset.save
              @query_dataset.save_in_miga( type: par[:type],
                description: params[:asm_description][idx],
                comments: params[:asm_comments][idx])
              saved_cnt += 1
            else
              @bad_objects << @query_dataset
            end
          end

          if saved_cnt > 0
            flash[:success] =
              pluralize(saved_cnt, 'dataset') + ' created successfully'
          end

          if @bad_objects.empty?
            if saved_cnt == 1
              redirect_to @query_dataset
            else
              redirect_to project_query_datasets_url(@project)
            end
          else
            render :new
          end
        end
      else
        par[:name] += '_' + SecureRandom.hex(4) if current_user.nil?
        @query_dataset = @project.query_datasets.create(par)
        if @query_dataset.save
          flash[:success] = 'Dataset created successfully'
          @query_dataset.save_in_miga( params )
          redirect_to @query_dataset
        else
          render :new
        end
      end
    end
  end

  def destroy
    qd = @query_dataset
    p = qd.project
    raise 'Unavailable project' if p.miga.nil?
    p.miga.unlink_dataset qd.miga_name
    qd.miga.remove! unless qd.miga.nil?
    qd.destroy
    redirect_to p
  end

  def result
    qd  = @query_dataset
    m   = qd.miga
    res = m.result(params[:result])
    if res.nil?
      render :nothing => true, :status => 200, :content_type => "text/html"
    else
      abs_path = res.file_path(params[:file])
      if Dir.exists?(abs_path) and params[:f] and not params[:f]=~/\//
        abs_path = File.expand_path(params[:f], abs_path)
      end
      if Dir.exists? abs_path
        @path = abs_path
        @file = File.basename abs_path
        @res  = res
        render template: "shared/result_dir"
      else
        type = case File.extname(abs_path)
          when ".pdf" ; "application/pdf"
          when ".html" ; "text/html"
          else ; "raw/text"
        end
        send_file(abs_path, filename: File.basename(abs_path),
          disposition: type=='text/html'?'inline':'attachment',
          type: type, x_sendfile: type!='text/html')
      end
    end
  end
  
  # Execute the MyTaxa Scan step upon request.
  def run_mytaxa_scan
    @query_dataset.run_mytaxa_scan!
    redirect_to(@query_dataset)
  end
  
  # Re-calculate the Distances step upon request.
  def run_distances
    @query_dataset.run_distances!
    redirect_to(@query_dataset)
  end

  # Mark dataset as unseen.
  def mark_unread
    @query_dataset.update(notified: false, complete_new: true)
    redirect_to(query_datasets_path)
  end

  private

    def query_dataset_params
      params.require(:query_dataset).permit(
        :name, :user_id, :project_id, :input_file, :input_file_2, :input_type)
    end

    def list_query_datasets
      if params[:project_id]
        @project = Project.find(params[:project_id])
        qd = params[:all] ? @project.query_datasets.all :
              QueryDataset.by_user_and_project(current_user, @project)
      else
        @project = nil
        qd = params[:all] ? QueryDataset.all : current_user.query_datasets
      end
      if params[:complete_new]
        qd = qd.select{ |i| i.complete_new }
      end
      @all_qd = qd.count
      params[:ready] ||= false
      if params[:ready] == 'yes'
        qd = qd.select do |i|
          begin
            i.ready?
          rescue JSON::ParserError => e
            flash[:alert] = "Malformed metadata: #{i.name}: #{e}"
            false
          end
        end
        @ready_qd = qd.count
        @running_qd = @all_qd - @ready_qd
      elsif params[:ready] == 'no'
        qd = qd.select do |i|
          begin
            not i.ready?
          rescue JSON::ParserError => e
            flash[:alert] = "Malformed metadata: #{i.name}: #{e}"
            true
          end
        end
        @running_qd = qd.count
        @ready_qd = @all_qd - @running_qd
      else
        @ready_qd = qd.select{ |i| i.ready? }.count
        @running_qd = @all_qd - @ready_qd
      end
      qd
    end

    # Sets the query dataset by ID or accession
    def set_query_dataset
      if params[:id] =~ /\AM:/
        @query_dataset = QueryDataset.find_by(acc: params[:id])
      else
        @query_dataset = QueryDataset.find(params[:id])
        flash.now[:warning] =
          'Entry IDs are being phased out, please update your links'
        # redirect_to root_url and return
      end
    end
      
    # Confirms the correct user
    def correct_user_or_admin
      @user = @query_dataset.user
      return true if @user.nil?
      redirect_to(root_url) if current_user.nil? or
        not( current_user?(@user) or current_user.admin? )
    end
end
