class AddStagingFlagToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :staging_flag, :boolean, default: false
  end
end
