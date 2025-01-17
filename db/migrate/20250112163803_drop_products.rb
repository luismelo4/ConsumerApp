class DropProducts < ActiveRecord::Migration[7.1]
  def change
    drop_table :products
  end
end
