class CreateAnimation < ActiveRecord::Migration
  def change
    create_table :animations do |t|
      t.string :title
      t.string :title_asin
      t.string :public_url
      t.integer :story_no
      t.string :pv_url
      t.string :blog_url
      t.text :description
      t.timestamps
    end
  end
end
