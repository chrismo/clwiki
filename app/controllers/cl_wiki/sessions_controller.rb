# frozen_string_literal: true

module ClWiki
  class SessionsController < ApplicationController
    before_action :skip_all_if_not_using_authentication
    skip_before_action :authorized, only: %i[new create]
    skip_before_action :initialize_index, only: %i[new create]

    def new
    end

    def create
      auth_user_and_setup_session ?
        redirect_to(root_url) :
        redirect_to(login_url)
    end

    def destroy
      reset_session
      redirect_to login_url
    end

    private

    def auth_user_and_setup_session
      @user = User.find(params[:username])
      password = params[:password]
      authenticated = @user&.username == $wiki_conf.owner && @user&.authenticate(password)
      if authenticated
        session[:username] = @user.username
        session[:expire_at] = 48.hours.from_now
        session[:encryption_key] = Base64.encode64(@user.derive_encryption_key(password))
      end
      authenticated
    end

    def skip_all_if_not_using_authentication
      redirect_to root_url unless $wiki_conf.use_authentication
    end
  end
end
