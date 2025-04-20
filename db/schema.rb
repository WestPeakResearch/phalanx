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

ActiveRecord::Schema[8.0].define(version: 2025_04_13_151146) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "applications", force: :cascade do |t|
    t.datetime "application_date"
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.integer "student_number"
    t.string "faculty"
    t.string "major"
    t.integer "year"
    t.string "grad_year"
    t.string "position"
    t.string "resume"
    t.string "additional"
    t.string "source"
    t.string "group_preference"
    t.string "countries"
    t.string "careers"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "selected_for_interview", default: false, null: false
  end

  create_table "documents", force: :cascade do |t|
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "initial_reviews", force: :cascade do |t|
    t.integer "application_id", null: false
    t.integer "decision"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["application_id"], name: "index_initial_reviews_on_application_id"
    t.index ["user_id"], name: "index_initial_reviews_on_user_id"
  end

  create_table "scorings", force: :cascade do |t|
    t.integer "application_id", null: false
    t.integer "user_id", null: false
    t.decimal "interest_score", precision: 3, scale: 2
    t.decimal "alignment_score", precision: 3, scale: 2
    t.decimal "polish_score", precision: 3, scale: 2
    t.integer "status", default: 0, null: false
    t.text "comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id", "user_id"], name: "index_scorings_on_application_id_and_user_id", unique: true
    t.index ["application_id"], name: "index_scorings_on_application_id"
    t.index ["user_id"], name: "index_scorings_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "name", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "initial_reviews", "applications"
  add_foreign_key "initial_reviews", "users"
  add_foreign_key "scorings", "applications"
  add_foreign_key "scorings", "users"
end
