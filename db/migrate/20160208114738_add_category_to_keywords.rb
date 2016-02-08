class AddCategoryToKeywords < ActiveRecord::Migration
  def change
    add_column :keywords, :category, :string
  end
end
