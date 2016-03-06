class CreateRookieAwards < ActiveRecord::Migration
  def change
    create_table :rookie_awards do |t|
      t.string :name, null: false
      t.string :public_url
      t.string :volume
      t.string :money
      t.string :submit_type
      t.string :image
      t.boolean :can_professional
      t.date :deadline_date
      t.text :note
      t.timestamps
    end
  end
end
