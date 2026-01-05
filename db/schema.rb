# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_05_121502) do
  create_table "documents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "document_date"
    t.integer "medical_folder_id", null: false
    t.text "notes"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["medical_folder_id"], name: "index_documents_on_medical_folder_id"
  end

  create_table "medical_folders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.string "specialty"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_medical_folders_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "shareable_links", force: :cascade do |t|
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.integer "medical_folder_id", null: false
    t.string "token"
    t.datetime "updated_at", null: false
    t.index ["medical_folder_id"], name: "index_shareable_links_on_medical_folder_id"
    t.index ["token"], name: "index_shareable_links_on_token", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "name"
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "documents", "medical_folders"
  add_foreign_key "medical_folders", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "shareable_links", "medical_folders"
end
