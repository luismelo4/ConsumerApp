class ChangeUrlColumnType < ActiveRecord::Migration[7.1]
  def change
    change_column :products, :url, :text
  end
end
