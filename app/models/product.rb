class Product < ApplicationRecord
  paginates_per 10
  
  validates_presence_of :country, :product_id, :price
  validates_uniqueness_of :product_id, scope: :shop_name
  validates_numericality_of :price, greater_than: 0
end