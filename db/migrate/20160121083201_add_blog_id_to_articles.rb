class AddBlogIdToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :blog_id, :string
  end
end
