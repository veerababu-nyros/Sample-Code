class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def facebook
    @user = User.find_for_facebook_oauth(request.env["omniauth.auth"])
 
    if @user.persisted? && User.where("secondary_email1 =?  or secondary_email2=?",@user.email,@user.email).blank?
      sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
      set_flash_message(:notice, :success, :kind => "Facebook") if is_navigational_format?
    else
      session["devise.facebook_data"] = request.env["omniauth.auth"]
      flash[:error] = "email already been taken"
      redirect_to new_user_registration_url
    end
  end
  
  def twitter
    @user = User.find_for_twitter_oauth(request.env["omniauth.auth"])

    if @user.persisted? && User.where("secondary_email1 =?  or secondary_email2=?",@user.email,@user.email).blank?
      sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
      set_flash_message(:notice, :success, :kind => "Twitter") if is_navigational_format?
    else
      session["devise.twitter_data"] = request.env["omniauth.auth"].except("extra")
      flash[:error] = "email already been taken"
      redirect_to new_user_registration_url
    end
  end
  
end
