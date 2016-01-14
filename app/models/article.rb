class Article < ActiveRecord::Base
  scope :recent, -> { order('id DESC') }

  class << self
    def new_post
      Article.create(title: "今は#{Time.now}", body: "#{Time.now.hour}時だよ")
    end
  end
end
