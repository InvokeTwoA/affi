class Admin::NgWordsController < Admin::ApplicationController
  inherit_resources

  def create
    create! do
      redirect_to admin_ng_words_path, notice: 'NGワードを追加しました' and return
    end
  end

  def update
    update! do
      redirect_to admin_ng_words_path, notice: 'NGワードを編集しました' and return
    end
  end

  private
  def collection
    @cond = params[:q] || {}
    @q = end_of_association_chain.search(@cond)
    @ng_words = NgWord.major.page(params[:page]).per(30).uniq
  end

  def ng_word_params
    params.require(:ng_word).permit(
      :name,
    )
  end
end
