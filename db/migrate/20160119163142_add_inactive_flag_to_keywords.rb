class AddInactiveFlagToKeywords < ActiveRecord::Migration
  def change
    add_column :keywords, :inactive_flag, :boolean
    add_column :articles, :target, :string
  end
end
