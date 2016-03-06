class Admin::AnimationsController < Admin::ApplicationController
  inherit_resources

  def create
    create! do
      redirect_to admin_animations_path and return
    end
  rescue => e
    redirect_to :back, flash: { error: "記事投稿に失敗しました。\n #{ e.message }" }
  end

  def update
    update! do
      redirect_to admin_animations_path and return
    end
  rescue => e
    redirect_to :back, flash: { error: "記事投稿に失敗しました。\n #{ e.message }" }
  end

  def post_article
    resource.post_article
    redirect_to admin_animations_path
  rescue => e
    redirect_to :back, flash: { error: "記事投稿に失敗しました。\n #{ e.message }" }
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
      :eng_title,
      :title_asin,
      :public_url,
      :story_no,
      :pv_url,
      :blog_id,
      :category,
      :description,
      :onair_youbi,
      :onair_hour,
    )
  end
end
