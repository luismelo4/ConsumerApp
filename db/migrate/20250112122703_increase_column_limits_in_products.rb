class IncreaseColumnLimitsInProducts < ActiveRecord::Migration[7.1]
  def change
    # Increase size limits of columns
    change_column :products, :country, :string, limit: 255 # Increased from 50 to 255
    change_column :products, :brand, :string, limit: 255   # Increased from 100 to 255
    change_column :products, :product_name, :string, limit: 500  # Increased from 200 to 500
    change_column :products, :shop_name, :string, limit: 255   # Increased from 100 to 255
    change_column :products, :url, :string, limit: 2048  # Increased from no limit to 2048 characters
    
    # You may also want to ensure the URL field is indexed with a higher size limit
    remove_index :products, :url
    add_index :products, :url, unique: true
  end
end
