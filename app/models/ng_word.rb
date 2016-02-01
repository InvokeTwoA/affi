class NgWord < ActiveRecord::Base
  scope :recent, -> { order('id DESC') }

  class << self
    def is_ok?(title)
      NgWord.recent.each do |ng_word|
        if title.include?(ng_word.name)
          ng_word.hits_count += 1
          ng_word.save!
          return false
        end
      end
      return true
    end
  end
end
