class Comment < ActiveRecord::Base
  belongs_to :article
  belongs_to :author, class_name: 'User'
end
