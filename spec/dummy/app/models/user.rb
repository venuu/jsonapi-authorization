class User < ActiveRecord::Base
  has_many :articles, as: :author
end
