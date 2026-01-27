class AddAccessCountToShareableLinks < ActiveRecord::Migration[8.1]
  def change
    add_column :shareable_links, :access_count, :integer, default: 0
    add_column :shareable_links, :access_limit, :integer  # nil = unlimited
  end
end
