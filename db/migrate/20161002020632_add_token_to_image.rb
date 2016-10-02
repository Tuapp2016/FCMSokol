class AddTokenToImage < ActiveRecord::Migration[5.0]
  def change
    add_reference :images, :token, foreign_key: true, index:true
  end
end
