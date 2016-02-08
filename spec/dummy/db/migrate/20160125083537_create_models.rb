class CreateModels < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.belongs_to :article
    end

    create_table :users do |t|
    end

    create_table :articles do |t|
      t.string :external_id, null: false
      t.references :author
    end
  end
end
