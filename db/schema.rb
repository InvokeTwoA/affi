# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160308202837) do

  create_table "animations", force: true do |t|
    t.string   "title"
    t.string   "title_asin"
    t.string   "public_url"
    t.integer  "story_no"
    t.string   "pv_url"
    t.string   "blog_id"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "eng_title"
    t.string   "category"
    t.string   "onair_youbi"
    t.integer  "onair_hour"
    t.string   "op"
    t.string   "ed"
    t.boolean  "is_active"
  end

  add_index "animations", ["is_active"], name: "index_animations_on_is_active", using: :btree

  create_table "articles", force: true do |t|
    t.string   "title"
    t.text     "body"
    t.string   "asin"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "author"
    t.boolean  "failed_flag"
    t.string   "category"
    t.string   "target"
    t.string   "image_url"
    t.string   "blog_id"
    t.datetime "deleted_at"
    t.boolean  "staging_flag", default: false
  end

  add_index "articles", ["category"], name: "index_articles_on_category", using: :btree

  create_table "keywords", force: true do |t|
    t.string   "name"
    t.string   "word_type"
    t.integer  "articles_count"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "inactive_flag"
    t.integer  "search_page",    default: 1
    t.string   "category"
  end

  create_table "ng_words", force: true do |t|
    t.string   "name"
    t.integer  "hits_count", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rookie_awards", force: true do |t|
    t.string   "name",             null: false
    t.string   "public_url"
    t.text     "volume"
    t.text     "money"
    t.string   "submit_type"
    t.string   "image"
    t.boolean  "can_professional"
    t.date     "deadline_date"
    t.text     "note"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "secrets_key_values", force: true do |t|
    t.string "k"
    t.string "v"
  end

  add_index "secrets_key_values", ["k"], name: "index_secrets_key_values_on_k", unique: true, using: :btree

end
