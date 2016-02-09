class Article < ActiveRecord::Base
  has_many :comments
  belongs_to :author, class_name: 'User'

  # Hack for easy include directive checks
  has_many :articles, -> { limit(2) }, foreign_key: :id
  has_one :article, foreign_key: :id
  has_one :non_existing_article, -> { none }, class_name: 'Article', foreign_key: :id
  has_many :empty_articles, -> { none }, class_name: 'Article', foreign_key: :id

  # Setting blank_value attribute is an easy way to test that authorizations
  # work even when the model has validation errors
  validate :blank_value_must_be_blank

  private

  def blank_value_must_be_blank
    errors.add(:blank_value, 'must be blank') unless blank_value.blank?
  end
end
