module ClWiki
  class ApplicationController < ActionController::Base
    before_action :authorized
    helper_method :current_user
    helper_method :logged_in?

    def current_user
      User.find(session[:username])
    end

    def logged_in?
      !current_user.nil?
    end

    def authorized
      redirect_to login_url unless logged_in?
    end
  end
end