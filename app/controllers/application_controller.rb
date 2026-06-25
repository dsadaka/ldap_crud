class ApplicationController < ActionController::Base
  before_action :check_session_expiry
  before_action :require_login
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user, :logged_in?

  # app/controllers/application_controller.rb

  private

  def current_user
    @current_user ||= session[:username] if session[:username]
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    unless logged_in?
      flash[:alert] = "You must be logged in to access this section."
      redirect_to login_path
    end
  end

  def check_session_expiry
    if session[:username] && session[:expires_at]
      if Time.current > Time.zone.parse(session[:expires_at])
        reset_session
        flash[:alert] = "Your session has expired. Please log in again."
        redirect_to login_path
      else
        # Refresh the expiration window on activity
        session[:expires_at] = 2.hours.from_now.to_s
      end
    end
  end
end
