class AnimationsController < ApplicationController
  inherit_resources

  def create
    create! do
      redirect_to animations_path and return
    end
  end

  def update
    update! do
      redirect_to animations_path and return
    end
  end

  def post_article
    resource.post_article
    redirect_to animations_path
  end

  private
  def collection
    @cond = params[:q] || {}
    @q = end_of_association_chain.search(@cond)
    @animations = @q.result.recent.page(params[:page]).per(30).uniq
  end

  def animation_params
    params.require(:animation).permit(
      :title,
      :title_asin,
      :public_url,
      :story_no,
      :pv_url,
      :description,
    )
  end
end
