# frozen_string_literal: true

class CreateModels < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.string :article_id
      t.belongs_to :author
      t.belongs_to :reviewing_user, references: :user
    end

    create_table :users

    create_table :articles do |t|
      t.string :external_id, null: false
      t.references :author
      t.string :blank_value
    end

    create_table :tags do |t|
      t.references :taggable, polymorphic: true
    end
  end
end
