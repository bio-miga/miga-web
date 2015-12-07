class ProjectsController < ApplicationController
   before_action :logged_in_user, only: [:new, :create, :destroy, :show, :result, :reference_datasets, :show_dataset, :reference_dataset_result]
   before_action :admin_user, only: [:new, :create, :destroy, :new_ncbi_download, :create_ncbi_download]

   def index
      @projects = Project.paginate(page: params[:page])
   end
   
   def new
      @project = Project.new
   end

   def show
      @project = Project.find(params[:id])
   end

   def reference_datasets
      @project = Project.find(params[:project_id])
      current_page = (params[:page] || 1).to_i
      per_page = (params[:per_page] || 30).to_i
      @ref_datasets = @project.ref_datasets
      @datasets = WillPaginate::Collection.create(current_page, per_page, @ref_datasets.size) do |pager|
	 start = (current_page-1)*per_page
	 pager.replace(@ref_datasets[start, per_page])
      end
   end

   def show_dataset
      @project = Project.find(params[:id])
      @dataset_miga = @project.miga.dataset(params[:dataset])
      redirect_to root_url unless @dataset_miga.is_ref?
   end
   
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

   def destroy
      project = Project.find(params[:id])
      FileUtils.rm_rf project.miga.path
      project.destroy
      flash[:success] = "Project deleted"
      redirect_to root_url
   end

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

   def new_ncbi_download
      @project = Project.find(params[:id])
   end
   
   def create_ncbi_download
      @project = Project.find(params[:project_id])
      species = params[:species] || ""
      codes = ""
      codes += "50|" if params[:complete]
      codes += "40|" if params[:chromosome]
      
      if codes.empty? or species.empty?
	 flash[:danger] = "Nothing to do, please set at least one status to download." if codes.empty?
	 flash[:danger] = "Nothing to do, please specify a species name." if species.empty?
	 render "new_ncbi_download"
      else
	 if g = @project.ncbi_download!(species, codes)
	    flash[:success] = "Downloaded #{g} reference genomes, processing..."
	    redirect_to @project
	 else
	    render "new_ncbi_download"
	 end
      end
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
	       send_file(f, filename:file, disposition:"inline", type:"application/pdf", x_sendfile:true)
	    when ".html"
	       send_file(f, filename:file, disposition:"inline", type:"text/html", x_sendfile:true)
	    else
	       send_file(f, filename:file, disposition:"inline", type:"raw/text", x_sendfile:true)
	    end
	 end
      end
end
