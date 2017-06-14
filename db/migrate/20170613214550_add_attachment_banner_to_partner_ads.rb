class AddAttachmentBannerToPartnerAds < ActiveRecord::Migration
  def self.up
    change_table :partner_ads do |t|
      t.attachment :banner
    end
  end

  def self.down
    remove_attachment :partner_ads, :banner
  end
end
