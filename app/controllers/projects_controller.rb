class ProjectsController < ApplicationController
   before_action :logged_in_user, only: [:new, :create, :destroy]
   before_action :admin_user, only: [:new, :create, :destroy]

   def index
      @projects = Project.paginate(page: params[:page])
   end
   
   def new
      @project = Project.new
   end

   def show
      @project = Project.find(params[:id])
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

   private

      def project_params
	 params.require(:project).permit(:path)
      end
end
