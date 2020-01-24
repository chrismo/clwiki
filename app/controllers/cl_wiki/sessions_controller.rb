# frozen_string_literal: true

module ClWiki
  class SessionsController < ApplicationController
    before_action :skip_all_if_not_using_authentication
    skip_before_action :authorized, only: %i[new create]
    skip_before_action :initialize_index, only: %i[new create]

    def new
    end

    def create
      @user = User.find(params[:username])
      password = params[:password]
      if @user&.username == $wiki_conf.owner && @user&.authenticate(password)
        session[:username] = @user.username
        session[:encryption_key] = Base64.encode64(@user.derive_encryption_key(password))
        redirect_to root_url
      else
        redirect_to login_url
      end
    end

    private

    def skip_all_if_not_using_authentication
      redirect_to root_url unless $wiki_conf.use_authentication
    end
  end
end
