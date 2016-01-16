class ArticlesController < ApplicationController
  #inherit_resources

  def index
    @articles = Article.recent.page(params[:page]).per(30).uniq
  end
  
  def create
    Article.new_post(params[:mode])
    redirect_to :back, notice: '投稿完了しました'
  rescue => e
    Article.create(title: '投稿失敗', body: e.message, failed_flag: true)
    redirect_to :back, flash: { error: "記事投稿に失敗しました。\n #{ e.message }" }
  end

  def destroy
    Article.destroy(params[:id])
    redirect_to :back, notice: '削除完了しました'
  rescue => e
    redirect_to :back, flash: { error: "削除に失敗しました。\n #{ e.message }" }
  end

end
