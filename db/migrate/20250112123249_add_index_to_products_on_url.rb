class AddIndexToProductsOnUrl < ActiveRecord::Migration[7.1]
  def change
    add_index :products, :url, unique: true, length: { url: 2048 }
  end
end
