class AddEngTitleToAnimations < ActiveRecord::Migration
  def change
    add_column :animations, :eng_title, :string
  end
end
