require 'rails_helper'

RSpec.describe MongoProduct, type: :model do
  it 'is valid with valid attributes' do
    product = MongoProduct.new(
      country: 'Portugal',
      brand: 'Nike',
      product_id: '12345',
      product_name: 'Running Shoes',
      shop_name: 'Nike Store',
      product_category_id: 1,
      price: 99.99,
      url: 'https://nike.com/running-shoes'
    )
    expect(product).to be_valid
  end

  it 'is invalid without a country' do
    product = MongoProduct.new(country: nil)
    expect(product).not_to be_valid
  end

  it 'is invalid without a product_id' do
    product = MongoProduct.new(product_id: nil)
    expect(product).not_to be_valid
  end

  it 'is invalid without a price' do
    product = MongoProduct.new(price: nil)
    expect(product).not_to be_valid
  end

  it 'is invalid with a duplicate product_id and shop_name' do
    existing_product = MongoProduct.create!(
      country: 'Portugal',
      brand: 'Nike',
      product_id: '12345',
      product_name: 'Running Shoes',
      shop_name: 'Nike Store',
      product_category_id: 1,
      price: 99.99,
      url: 'https://nike.com/running-shoes'
    )

    new_product = MongoProduct.new(
      country: 'USA',
      brand: 'Nike',
      product_id: '12345',
      product_name: 'Running Shoes',
      shop_name: 'Nike Store',
      product_category_id: 1,
      price: 99.99,
      url: 'https://nike.com/usa-running-shoes'
    )
    expect(new_product).not_to be_valid
  end

  it 'has a country field of type String' do
    product = MongoProduct.new(country: 'Portugal')
    expect(product.country).to be_a(String)
  end

  it 'has a price field of type Float' do
    product = MongoProduct.new(price: 99.99)
    expect(product.price).to be_a(Float)
  end

  it 'has a product_category_id field of type Integer' do
    product = MongoProduct.new(product_category_id: 1)
    expect(product.product_category_id).to be_a(Integer)
  end
end
