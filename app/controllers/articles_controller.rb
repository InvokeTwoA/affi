class ArticlesController < ApplicationController
  inherit_resources

  def index
    @articles = Article.recent.page(params[:page]).per(30).uniq
  end
  
  def create
    if params[:word].present?
      Article.new_post(nil, params[:word])
    else
      Article.new_post(params[:mode])
    end
    redirect_to :back, notice: '投稿完了しました'
  rescue => e
    Article.create(title: '投稿失敗', body: e.message, failed_flag: true)
    redirect_to :back, flash: { error: "記事投稿に失敗しました。\n #{ e.message }" }
  end

  def destroy
    destroy! do
      redirect_to :back, notice: '削除完了しました' and return
    end
  rescue => e
    redirect_to :back, flash: { error: "削除に失敗しました。\n #{ e.message }" }
  end

  def rm_hatena
    resource.rm_hatena_blog
    redirect_to :back, notice: 'はてなの記事を削除しました'
  rescue => e
    redirect_to :back, flash: { error: "削除に失敗しました。\n #{ e.message }" }
  end

end
