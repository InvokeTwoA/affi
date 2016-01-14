class RootsController < ApplicationController
  #inherit_resources
  
  def index
    @articles = Article.recent
  end
  
end
