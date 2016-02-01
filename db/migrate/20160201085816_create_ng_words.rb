class CreateNgWords < ActiveRecord::Migration
  def change
    create_table :ng_words do |t|
      t.string :name
      t.integer :hits_count, default: 0
      t.timestamps
    end
  end
end
