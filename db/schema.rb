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

ActiveRecord::Schema.define(version: 20160118063650) do

  create_table "animations", force: true do |t|
    t.string   "title"
    t.string   "title_asin"
    t.string   "public_url"
    t.integer  "story_no"
    t.string   "pv_url"
    t.string   "blog_url"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "articles", force: true do |t|
    t.string   "title"
    t.text     "body"
    t.string   "asin"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "author"
    t.boolean  "failed_flag"
    t.string   "category"
  end

  add_index "articles", ["category"], name: "index_articles_on_category", using: :btree

  create_table "keywords", force: true do |t|
    t.string   "name"
    t.string   "word_type"
    t.integer  "articles_count"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
