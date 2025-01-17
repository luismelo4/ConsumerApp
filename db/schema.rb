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

ActiveRecord::Schema[7.1].define(version: 2025_01_17_124506) do
  create_table "products", force: :cascade do |t|
    t.string "country", limit: 50, null: false
    t.string "brand", limit: 100, null: false
    t.string "product_id", null: false
    t.string "product_name", limit: 200, null: false
    t.string "shop_name", limit: 100, null: false
    t.integer "product_category_id", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.string "url", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country", "product_id", "shop_name"], name: "index_products_on_country_and_product_id_and_shop_name", unique: true
  end

end
