FactoryBot.define do
  factory :product do
    country { "MyString" }
    brand { "MyString" }
    product_id { "MyString" }
    product_name { "MyString" }
    shop_name { "MyString" }
    product_category_id { 1 }
    price { 1.5 }
    url { "MyString" }
  end
end
