class AddRouteToImages < ActiveRecord::Migration[5.0]
  def change
    add_column :images, :route, :text
    add_index :images, :route
  end
end
