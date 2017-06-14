class CreatePartnerAds < ActiveRecord::Migration
  def change
    create_table :partner_ads do |t|
      t.references :event, index: true, foreign_key: true, null: false
      t.string :image, null: false
      t.string :link, null: false
      t.integer :weight, null: false, default: 1

      t.timestamps null: false
    end
  end
end
