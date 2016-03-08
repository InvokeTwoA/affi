class AddOpAndEdToAnimations < ActiveRecord::Migration
  def change
    add_column :animations, :op, :string
    add_column :animations, :ed, :string
    add_column :animations, :is_active, :boolean

    add_index :animations, :is_active

    Animation.all.each do |animation|
      animation.is_active = true
      animation.save!
    end
  end
end
