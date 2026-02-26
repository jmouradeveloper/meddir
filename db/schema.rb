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

ActiveRecord::Schema[8.1].define(version: 2026_01_27_200712) do
  create_schema "extensions"

  # These are extensions that must be enabled in order to support this database
  enable_extension "extensions.pg_stat_statements"
  enable_extension "extensions.pgcrypto"
  enable_extension "extensions.uuid-ossp"
  # enable_extension "graphql.pg_graphql" # Supabase Vault extension is not compatible with this extension
  enable_extension "pg_catalog.plpgsql"
  # enable_extension "vault.supabase_vault" # Supabase Vault extension is not compatible with this extension

  create_table "public.active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "public.active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "public.active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "public.documents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "document_date"
    t.bigint "medical_folder_id", null: false
    t.text "notes"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["medical_folder_id"], name: "index_documents_on_medical_folder_id"
  end

  create_table "public.medical_folders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.string "specialty"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_medical_folders_on_user_id"
  end

  create_table "public.plans", force: :cascade do |t|
    t.boolean "active", default: true
    t.integer "active_links_limit"
    t.decimal "annual_price", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.integer "folders_limit"
    t.integer "link_access_limit"
    t.decimal "monthly_price", precision: 10, scale: 2
    t.string "name", null: false
    t.boolean "sharing_enabled", default: false
    t.string "slug", null: false
    t.integer "storage_limit_mb"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_plans_on_slug", unique: true
  end

  create_table "public.sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "public.shareable_links", force: :cascade do |t|
    t.integer "access_count", default: 0
    t.integer "access_limit"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.bigint "medical_folder_id", null: false
    t.string "token"
    t.datetime "updated_at", null: false
    t.index ["medical_folder_id"], name: "index_shareable_links_on_medical_folder_id"
    t.index ["token"], name: "index_shareable_links_on_token", unique: true
  end

  create_table "public.subscriptions", force: :cascade do |t|
    t.string "billing_cycle", default: "monthly"
    t.datetime "created_at", null: false
    t.datetime "ends_at"
    t.text "notes"
    t.bigint "plan_id", null: false
    t.datetime "starts_at"
    t.string "status", default: "active"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["plan_id"], name: "index_subscriptions_on_plan_id"
    t.index ["user_id"], name: "index_subscriptions_on_user_id", unique: true
  end

  create_table "public.users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "locale"
    t.string "name"
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "public.active_storage_attachments", "public.active_storage_blobs", column: "blob_id"
  add_foreign_key "public.active_storage_variant_records", "public.active_storage_blobs", column: "blob_id"
  add_foreign_key "public.documents", "public.medical_folders"
  add_foreign_key "public.medical_folders", "public.users"
  add_foreign_key "public.sessions", "public.users"
  add_foreign_key "public.shareable_links", "public.medical_folders"
  add_foreign_key "public.subscriptions", "public.plans"
  add_foreign_key "public.subscriptions", "public.users"

end
