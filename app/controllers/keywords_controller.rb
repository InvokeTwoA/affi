class KeywordsController < ApplicationController
  inherit_resources

  def create
    create! do
      redirect_to keywords_path, notice: 'キーワードを追加しました' and return
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
    )

  end
end
