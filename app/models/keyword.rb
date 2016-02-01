# -*- encoding: utf-8 -*-
class Keyword < ActiveRecord::Base
  scope :recent, -> { order('id DESC') }
  scope :active, -> { where("inactive_flag IS NULL OR inactive_flag = false") }
  scope :inactive, -> { where(inactive_flag: true) }

  scope :general, -> { where(word_type: 'general')}
  scope :idol, -> { where(word_type: 'idol')}
  scope :maid, -> { where(word_type: 'maid')}

  class << self
    # グラビア関係のキーワード
    def select_idol_word(mode)
      if mode == "idol"
        id = idol.recent.active.pluck(:id).sample
        keyword = Keyword.find id
      else
        id_list = general.active.pluck(:id) + idol.active.pluck(:id)
        id = id_list.sample
        keyword = Keyword.find id
      end
    end

    # メイド関係のキーワード
    def select_maid_word
      id = maid.recent.active.pluck(:id).sample
      Keyword.find id
    end
  end
end
