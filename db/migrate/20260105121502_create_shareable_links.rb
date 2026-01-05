class CreateShareableLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :shareable_links do |t|
      t.references :medical_folder, null: false, foreign_key: true
      t.string :token
      t.datetime :expires_at
      t.boolean :active

      t.timestamps
    end
    add_index :shareable_links, :token, unique: true
  end
end
