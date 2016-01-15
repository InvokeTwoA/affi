class RootsController < ApplicationController
  #inherit_resources
  before_filter :authenticate
  
  def index
    @articles = Article.recent
  end
  
  protected
  def authenticate
    authenticate_or_request_with_http_basic('Administration') do |username, password|
      username == 'ike' && password == 'men'
    end
  end
end
