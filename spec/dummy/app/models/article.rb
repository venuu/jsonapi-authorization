class Article < ActiveRecord::Base
  has_many :comments
  has_many :tags, as: :taggable
  belongs_to :author, class_name: 'User'

  def to_param
    external_id
  end
end
