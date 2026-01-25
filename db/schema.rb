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

ActiveRecord::Schema[8.1].define(version: 2026_01_25_100002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
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

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "business_cards", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "extracted_data"
    t.text "ocr_raw_text"
    t.integer "status"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "visibility"
    t.index ["user_id"], name: "index_business_cards_on_user_id"
  end

  create_table "charge_entries", force: :cascade do |t|
    t.integer "amount_yen"
    t.string "category"
    t.string "counterparty"
    t.datetime "created_at", null: false
    t.integer "direction"
    t.text "note"
    t.date "occurred_on"
    t.datetime "updated_at", null: false
  end

  create_table "conversations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "mode"
    t.datetime "updated_at", null: false
    t.index ["mode"], name: "index_conversations_on_mode"
  end

  create_table "daily_contexts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date"
    t.text "morning_focus"
    t.text "next_actions"
    t.text "risks"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_daily_contexts_on_user_id"
  end

  create_table "hyper_secretary_messages", force: :cascade do |t|
    t.integer "amount_yen"
    t.string "category"
    t.integer "charge_entry_id"
    t.text "content"
    t.string "counterparty"
    t.datetime "created_at", null: false
    t.integer "direction"
    t.jsonb "extracted"
    t.string "kind"
    t.string "role"
    t.datetime "updated_at", null: false
    t.index ["charge_entry_id"], name: "index_hyper_secretary_messages_on_charge_entry_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text "content"
    t.bigint "conversation_id"
    t.datetime "created_at", null: false
    t.jsonb "metadata"
    t.integer "role"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.integer "visibility"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "kind"
    t.datetime "read_at"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "receipts", force: :cascade do |t|
    t.integer "bucket"
    t.datetime "created_at", null: false
    t.jsonb "extracted_data"
    t.string "note"
    t.text "ocr_raw_text"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "visibility"
    t.index ["user_id"], name: "index_receipts_on_user_id"
  end

  create_table "user_preferences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "strictness", default: 1
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_user_preferences_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "secret_pin_digest"
    t.datetime "secret_unlocked_at"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "vault_entries", force: :cascade do |t|
    t.integer "amount_yen"
    t.string "category"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.datetime "expires_at"
    t.boolean "hidden"
    t.integer "kind"
    t.text "memo"
    t.date "occurred_on"
    t.text "ocr_error"
    t.string "ocr_status"
    t.string "ocr_target"
    t.jsonb "parsed_json"
    t.date "purge_on"
    t.datetime "purge_warned_at"
    t.string "tag"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "business_cards", "users"
  add_foreign_key "daily_contexts", "users"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "users"
  add_foreign_key "receipts", "users"
  add_foreign_key "user_preferences", "users"
end
