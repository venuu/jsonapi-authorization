class User < ActiveRecord::Base
  has_many :articles, as: :author
  has_many :comments, as: :author
end
