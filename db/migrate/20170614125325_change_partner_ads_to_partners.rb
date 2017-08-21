class ChangePartnerAdsToPartners < ActiveRecord::Migration
  def change
    rename_table :partner_ads, :partners
    rename_column :partners, :link, :banner_link
    add_column :partners, :name, :string
  end
end
