class RemoveImageFromPartnerAd < ActiveRecord::Migration
  def change
    remove_column :partner_ads, :image, :string
  end
end
