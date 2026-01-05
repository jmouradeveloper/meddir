class CreateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :documents do |t|
      t.references :medical_folder, null: false, foreign_key: true
      t.string :title
      t.date :document_date
      t.text :notes

      t.timestamps
    end
  end
end
