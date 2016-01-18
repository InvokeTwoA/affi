class AddCategoryToAnimations < ActiveRecord::Migration
  def change
    add_column :animations, :category, :string
  end
end
