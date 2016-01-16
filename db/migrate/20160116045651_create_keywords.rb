class CreateKeywords < ActiveRecord::Migration
  def change
    create_table :keywords do |t|
      t.string :name
      t.string :word_type
      t.integer :articles_count
      t.timestamps
    end
  end
end
