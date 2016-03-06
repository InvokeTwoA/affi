class Admin::ArticlesController < Admin::ApplicationController
  inherit_resources
  respond_to :js

  def all_articles
    @articles = Article.recent.page(params[:page]).per(30).uniq
    render :index
  end
  
  def create
    if params[:word].present?
      article = Article.new_post(params[:mode], params[:word], false, params[:url_type])
    else
      article = Article.new_post(nil, nil, false, params[:url_type])
    end
    redirect_to article_path(article), notice: '投稿完了しました'
  rescue => e
    redirect_to :back, flash: { error: "記事投稿に失敗しました。\n #{ e.message }" }
  end

  # 記事更新
  def update
    update! do
      resource.update_blog(resource.target)
      return redirect_to articles_path, notice: '更新しました'
    end
  end

  def post_hatena
    resource.upload_hatena(params[:url_type])
    redirect_to articles_path, notice: '投稿完了しました'
  rescue => e
    redirect_to :back, flash: { error: "記事投稿に失敗しました。\n #{ e.message }" }
  end

  def destroy
    destroy! do |format|
      format.js {render 'destroy'}
      format.html { redirect_to :back, notice: '削除完了しました' and return }
    end
  rescue => e
    redirect_to :back, flash: { error: "削除に失敗しました。\n #{ e.message }" }
  end

  # はてなの記事非公開
  def rm_hatena
    resource.rm_hatena_blog(params[:url_type])
    respond_to do |format|
      format.js {render 'rm_hatena'}
      format.html {redirect_to articles_path, notice: 'はてなの記事を削除しました'}
    end
  rescue => e
    redirect_to :back, flash: { error: "記事非公開に失敗しました。\n #{ e.message }" }
  end

  # 記事を公開せず deleted_at を設定する
  def rm_blog
    resource.rm_blog
    respond_to do |format|
      format.js {render 'rm_blog'}
      format.html {redirect_to articles_path, notice: 'delted_at を設定しました'}
    end
  rescue => e
    redirect_to :back, flash: { error: "削除に失敗しました。\n #{ e.message }" }
  end

  private
  def collection
    @articles = Article.active.recent.page(params[:page]).per(30).uniq
  end

  def article_params
    params.require(:article).permit(
      :title,
      :category,
      :body,
    )
  end
end
