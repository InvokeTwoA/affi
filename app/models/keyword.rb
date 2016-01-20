# -*- encoding: utf-8 -*-
class Keyword < ActiveRecord::Base
  scope :recent, -> { order('id DESC') }
  scope :active, -> { where("inactive_flag IS NULL OR inactive_flag = false") }
  scope :inactive, -> { where(inactive_flag: true) }

  scope :general, -> { where(word_type: 'general')}
  scope :idol, -> { where(word_type: 'idol')}

  class << self
    def select_word(mode)
      if mode == "idol"
        id = idol.active.pluck(:id).sample
        keyword = Keyword.find id
      else
        id = recent.active.pluck(:id).sample
        keyword = Keyword.find id
      end
    end
  end
end
