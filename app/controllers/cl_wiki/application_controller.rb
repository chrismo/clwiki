module ClWiki
  class ApplicationController < ActionController::Base
    before_action :authorized, if: -> { $wiki_conf.use_authentication }
    helper_method :current_user
    helper_method :logged_in?

    def current_user
      User.find(session[:username])&.tap do |user|
        user.cached_encryption_key = session[:encryption_key]
      end
    end

    def logged_in?
      !current_user.nil?
    end

    def authorized
      redirect_to login_url unless logged_in?
    end
  end
end