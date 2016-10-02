class Token < ApplicationRecord
  has_many :images, dependent: :destroy
  validates :token_id, :uniqueness=>true, :presence=>true
end
