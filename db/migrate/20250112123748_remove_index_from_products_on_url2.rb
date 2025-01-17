class RemoveIndexFromProductsOnUrl2 < ActiveRecord::Migration[7.1]
  def change
    remove_index :products, :url
  end
end
