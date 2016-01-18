class ChangeBlogUrl < ActiveRecord::Migration
  def change
    rename_column :animations, :blog_url, :blog_id
  end
end
