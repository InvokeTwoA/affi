# -*- encoding: utf-8 -*-
class Keyword < ActiveRecord::Base
  scope :recent, -> { order('id DESC') }
  scope :active, -> { where.not(inactive_flag: true) }
  scope :inactive, -> { where(inactive_flag: true) }

  scope :general, -> { where(word_type: 'general')}
  scope :idol, -> { where(word_type: 'idol')}

  class << self
    def select_word(mode)
      if mode == "idol"
        word = idol.active.pluck(:name).sample
      else
        word = recent.active.pluck(:name).sample
      end
    end
  end
end
