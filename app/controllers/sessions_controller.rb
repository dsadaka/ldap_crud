# frozen_string_literal: true

# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  # Skip enforcement so users can actually see the login page
  skip_before_action :require_login, only: [:new, :create]
  skip_before_action :check_session_expiry, only: [:new, :create]

  def new
    # Renders the login form
  end

  def create
    username = params[:username]
    password = params[:password]

    # Load credentials from YAML
    config = YAML.load_file(Rails.root.join("config/creds.yml"))
    user_data = config.dig("users", username)

    if user_data && BCrypt::Password.new(user_data["password_digest"]) == password
      # Clear old session data entirely for security before writing new keys
      reset_session

      session[:username] = username
      session[:expires_at] = 2.hours.from_now.to_s

      flash[:notice] = "Logged in successfully!"
      redirect_to root_path
    else
      flash.now[:alert] = "Invalid username or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    flash[:notice] = "You have been logged out."
    redirect_to login_path
  end
end