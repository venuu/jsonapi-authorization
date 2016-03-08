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

ActiveRecord::Schema.define(version: 20160125083537) do

  create_table "articles", force: :cascade do |t|
    t.string  "external_id", null: false
    t.integer "author_id"
    t.string  "blank_value"
  end

  create_table "comments", force: :cascade do |t|
    t.integer "article_id"
    t.integer "author_id"
  end

  create_table "tags", force: :cascade do |t|
    t.integer "taggable_id"
    t.string  "taggable_type"
  end

  create_table "users", force: :cascade do |t|
  end

end
