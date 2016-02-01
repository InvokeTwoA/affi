class NgWord < ActiveRecord::Base
  scope :recent, -> { order('id DESC') }
end
