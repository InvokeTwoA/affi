class AddUpdateDateToAnimations < ActiveRecord::Migration
  def change
    add_column :animations, :onair_youbi, :string
    add_column :animations, :onair_hour, :integer
  end
end
