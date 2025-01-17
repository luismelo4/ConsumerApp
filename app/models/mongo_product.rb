class MongoProduct
  include Mongoid::Document
  include Kaminari::ActiveRecordExtension # This allows for Kaminari pagination

  field :country, type: String
  field :brand, type: String
  field :product_id, type: String
  field :product_name, type: String
  field :shop_name, type: String
  field :product_category_id, type: Integer
  field :price, type: Float
  field :url, type: String

  validates_presence_of :country, :product_id, :price
  validates_uniqueness_of :product_id, scope: :shop_name
  validates_numericality_of :price, greater_than: 0
end
