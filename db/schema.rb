# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_08_10_173407) do

  create_table "projects", force: :cascade do |t|
    t.text "path"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "private", default: false
    t.boolean "official", default: true
    t.boolean "reference", default: false
    t.index ["official"], name: "index_projects_on_official"
    t.index ["path"], name: "index_projects_on_path", unique: true
    t.index ["private"], name: "index_projects_on_private"
    t.index ["user_id", "created_at"], name: "index_projects_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_projects_on_user_id"
  end

  create_table "query_datasets", force: :cascade do |t|
    t.text "name"
    t.boolean "complete", default: false
    t.integer "user_id"
    t.integer "project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "input_file"
    t.string "input_type"
    t.string "input_file_2"
    t.boolean "notified", default: false
    t.boolean "complete_new", default: false
    t.string "acc"
    t.index ["acc"], name: "index_query_datasets_on_acc", unique: true
    t.index ["project_id", "created_at"], name: "index_query_datasets_on_project_id_and_created_at"
    t.index ["project_id", "user_id", "name"], name: "index_query_datasets_on_project_id_and_user_id_and_name", unique: true
    t.index ["project_id"], name: "index_query_datasets_on_project_id"
    t.index ["user_id", "created_at"], name: "index_query_datasets_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_query_datasets_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.string "remember_digest"
    t.boolean "admin", default: false
    t.string "activation_digest"
    t.boolean "activated", default: false
    t.datetime "activated_at"
    t.string "reset_digest"
    t.datetime "reset_sent_at"
    t.boolean "notify", default: true
    t.index ["email"], name: "index_users_on_email", unique: true
  end

end
