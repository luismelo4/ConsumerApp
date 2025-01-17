class AddUniqueIndexToProducts < ActiveRecord::Migration[7.1]
  def change
        # This assumes you're using Mongoid for MongoDB in Rails
        MongoProduct.collection.indexes.create_one(
          { country: 1, product_id: 1, shop_name: 1 },
          { unique: true, name: 'unique_product_index' }
        )
  end
end

