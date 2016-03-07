class ChangeTextToRookieAwards < ActiveRecord::Migration
  def change
    change_column :rookie_awards, :volume, :text
    change_column :rookie_awards, :money, :text
  end
end
