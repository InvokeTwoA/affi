class RookieAwardsController < ApplicationController
  inherit_resources
  respond_to :js

  private
  def collection
    @cond ||= params[:q] || {}
    @q = end_of_association_chain.search(@cond)
    @rookie_awards = @q.result.recent.page(params[:page]).per(30).uniq
  end
end
