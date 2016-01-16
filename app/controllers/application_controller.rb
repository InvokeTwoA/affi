class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_filter :authenticate

  protected
  def authenticate
    authenticate_or_request_with_http_basic('Administration') do |username, password|
      username == 'ike' && password == 'men'
    end
  end
end
