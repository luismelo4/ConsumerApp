class ModifyProductsAllowNulls < ActiveRecord::Migration[7.1]
  def change
        change_column_null :products, :brand, true
        change_column_null :products, :product_name, true
        change_column_null :products, :product_category_id, true
        change_column_null :products, :price, true
        change_column_null :products, :url, true
  end   
end
