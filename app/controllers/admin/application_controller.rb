class Admin::ApplicationController < ApplicationController
  layout 'admin_application'
  protect_from_forgery with: :exception
  before_filter :authenticate

  protected
  def authenticate
    authenticate_or_request_with_http_basic('Administration') do |username, password|
      username == SecretsKeyValue.return_value('basic_id') && password == SecretsKeyValue.return_value('basic_pwd')
    end
  end
end
