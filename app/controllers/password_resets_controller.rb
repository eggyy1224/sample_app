class PasswordResetsController < ApplicationController
  before_action :get_user,   only: [:edit, :update]
  before_action :valid_user, only: [:edit, :update]
  before_action :check_expiration, only: [:edit, :update]#token已過時效

  def new
  end

  def create
    @user = User.find_by(email: params[:password_reset][:email].downcase)
    
    if @user
      @user.create_reset_digest#如果存在的話就產生摘要以及寄發信件
      @user.send_password_reset_email
      flash[:info] = "Email sent with password reset instructions"
      redirect_to root_url
    else
      flash[:danger] = "Email address not found"
      render 'new'
    end
  end

  def edit
  end

  def update
    if params[:user][:password].empty? #沒有填寫密碼
      @user.errors.add(:password, "can't be empty")
      render 'edit'
    elsif @user.update_attributes(user_params)#update_attributes會經過驗證程序，update_attribute則不會
      log_in @user 
      flash[:success] = "Password has been reset"
      @user.update_attribute(:reset_digest, nil)
      redirect_to @user#user_path(@user的縮寫)
    else#密碼無效
      render 'edit'
    end
  end

  private

    def user_params
      params.require(:user).permit(:password, :password_confirmation)
    end

    def get_user
      @user = User.find_by(email: params[:email])
    end

    def valid_user
      unless (@user && @user.activated? && @user.authenticated?(:reset, params[:id]))
        redirect_to root_url
      end
    end

    def check_expiration
      if @user.password_reset_expired?
        flash[:danger] = "Password reset has expired"
        redirect_to new_password_reset_url
        

      end
    end
end
