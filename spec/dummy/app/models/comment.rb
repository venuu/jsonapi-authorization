class Comment < ActiveRecord::Base
  has_many :tags, as: :taggable
  belongs_to :article
end
