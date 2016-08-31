class Token < ApplicationRecord
  validates :token_id, uniqueness: true
end
