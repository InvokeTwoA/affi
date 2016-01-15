class AddFailedFlagToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :failed_flag, :boolean
  end
end
