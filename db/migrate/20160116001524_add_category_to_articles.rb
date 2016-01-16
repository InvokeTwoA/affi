class AddCategoryToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :category, :string
    add_index :articles, :category
  end
end
