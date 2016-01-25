class CreateSecretsKeyValues < ActiveRecord::Migration
  def change
    create_table :secrets_key_values do |t|
      t.string :k, nul: false
      t.string :v
      t.index :k, unique: true
    end
  end
end
