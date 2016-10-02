class Image < ApplicationRecord
  mount_uploader :image, ImageUploader
  validates :image, :presence=>true
  validates :route, :presence=>true
  belongs_to :token
end
