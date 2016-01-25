class Article < ActiveRecord::Base
  has_many :comments
  belongs_to :author, class_name: 'User'
end
