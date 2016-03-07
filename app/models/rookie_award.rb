class RookieAward < ActiveRecord::Base
  scope :recent, -> { order('deadline_date ASC') }
end
