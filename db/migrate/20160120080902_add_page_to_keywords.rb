class AddPageToKeywords < ActiveRecord::Migration
  def change
    add_column :keywords, :search_page, :integer, default: 1
  end
end
