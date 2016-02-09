class CreateModels < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.belongs_to :article
      t.belongs_to :author
    end

    create_table :users do |t|
    end

    create_table :articles do |t|
      t.references :author
      t.string :blank_value
    end
  end
end
