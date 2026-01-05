class CreateMedicalFolders < ActiveRecord::Migration[8.1]
  def change
    create_table :medical_folders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.string :specialty
      t.text :description

      t.timestamps
    end
  end
end
