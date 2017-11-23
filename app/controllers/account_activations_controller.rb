class AccountActivationsController < ApplicationController
  def edit
    user = User.find_by(email: params[:email])
    if user && !user.activated && user.authenticated?(:activation, params[:id])#使用者存在且還沒被激活且要通過激活認證
      user.activate
      log_in user
      flash[:success] = "Account activated!"
      redirect_to user#user_path(user的簡寫)
    else
      flash[:danger] = "Invalid activation link"
      redirect_to root_url
    end
  end
  
end
