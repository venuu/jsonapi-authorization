class Comment < ActiveRecord::Base
  has_many :tags, as: :taggable
  belongs_to :article
  belongs_to :author, class_name: 'User'
end
