class CreateProducts3 < ActiveRecord::Migration[7.1]
  def change
    create_table :products do |t|
      t.string :country, null: false, limit: 50
      t.string :brand, null: false, limit: 100
      t.string :product_id, null: false
      t.string :product_name, null: false, limit: 200
      t.string :shop_name, null: false, limit: 100
      t.integer :product_category_id, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.string :url, null: false
    
      t.timestamps
    end
    
    # Add the primary key as a single column (id)
    add_index :products, [:country, :product_id, :shop_name], unique: true    
  end
end