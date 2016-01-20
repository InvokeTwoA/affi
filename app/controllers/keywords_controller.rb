class KeywordsController < ApplicationController
  inherit_resources

  def to_active
    resource.inactive_flag = false
    resource.save!
    redirect_to keywords_path, notice: 'キーワードを有効にしました' and return
  end

  def to_inactive
    resource.inactive_flag = true
    resource.save!
    redirect_to keywords_path, notice: 'キーワードを無効にしました' and return
  end

  def create
    create! do
      redirect_to keywords_path, notice: 'キーワードを追加しました' and return
    end
  end

  def update
    update! do
      redirect_to keywords_path, notice: 'キーワードを編集しました' and return
    end
  end

  def collection
    @cond = params[:q] || {}
    @q = end_of_association_chain.search(@cond)
    @keywords = Keyword.recent.page(params[:page]).per(30).uniq
  end

  def keyword_params
    params.require(:keyword).permit(
      :name,
      :word_type,
      :search_page,
    )
  end
end
