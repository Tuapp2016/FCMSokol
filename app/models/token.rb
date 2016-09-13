class Token < ApplicationRecord
  validates :token_id, :uniqueness=>true, :presence=>true
end
