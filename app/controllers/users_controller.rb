class UsersController < ApplicationController
  before_action :logged_in_user,
    only: [:index, :edit, :update, :destroy, :show, :dashboard]
  before_action :correct_user,   only: [:edit, :update, :show]
  before_action :admin_user,
    only: [:index, :destroy, :unactivated_users, :activate_user, :admin]

  # Show all users
  def index
    @users = User.paginate(page: params[:page])
  end

  # Show user dashboard
  def dashboard
  end

  # Show site admin console
  def admin
  end
  
  def show
     @user = User.find(params[:id])
  end
  
  def new
     @user = User.new
  end

  def create
    par = user_params
    if User.all.empty?
      par[:activated] = true
      par[:activated_at] = Time.zone.now
      par[:admin] = true
    end
    @user = User.new(par)
    if @user.save
      if @user.activated?
        flash[:info] = 'User created, please login.'
      else
        @user.send_activation_email
        flash[:info] = 'Please check your email to activate your account.'
      end
      redirect_to root_url
    else
      render 'new'
    end
  end

  def edit
     @user = User.find(params[:id])
  end

  def update
     @user = User.find(params[:id])
     if @user.update(user_params)
	flash[:success] = 'Profile updated'
	redirect_to @user
     else
	render 'edit'
     end
  end

  def destroy
     User.find(params[:id]).destroy
     flash[:success] = 'User deleted'
     redirect_to users_url
  end
  
  # created a unactivatedusers method
  def unactivated_users
    @users = User.where(activated: false).paginate(page: params[:page])
  end

  # admin manually activate user account
  def activate_user
    @user = User.find(params[:id])
    if @user.activate
      flash[:success] = 'activated'
    else
      flash[:danger] = 'Failed to activate user'
    end
    redirect_to unactivated_users_url
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password,
      :password_confirmation)
  end

  # Before filters

  # Confirms the correct user
  def correct_user
    @user = User.find(params[:id])
    unless current_user?(@user) || current_user.admin?
      flash[:danger] = 'You don\'t have privileges to access this page'
      redirect_to(root_url)
    end
  end
end
