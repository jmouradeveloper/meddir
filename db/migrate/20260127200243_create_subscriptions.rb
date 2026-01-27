class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.references :plan, null: false, foreign_key: true
      t.string :billing_cycle, default: "monthly"  # monthly, annual
      t.string :status, default: "active"          # active, cancelled, expired
      t.datetime :starts_at
      t.datetime :ends_at
      t.text :notes  # for manual control notes

      t.timestamps
    end
  end
end
