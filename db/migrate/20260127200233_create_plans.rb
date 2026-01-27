class CreatePlans < ActiveRecord::Migration[8.1]
  def change
    create_table :plans do |t|
      t.string :name, null: false
      t.string :slug, null: false, index: { unique: true }
      t.integer :storage_limit_mb          # nil = unlimited
      t.integer :folders_limit             # nil = unlimited
      t.integer :active_links_limit        # nil = unlimited
      t.integer :link_access_limit         # nil = unlimited
      t.boolean :sharing_enabled, default: false
      t.decimal :monthly_price, precision: 10, scale: 2
      t.decimal :annual_price, precision: 10, scale: 2
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
