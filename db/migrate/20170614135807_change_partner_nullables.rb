class ChangePartnerNullables < ActiveRecord::Migration
  def self.up
    Partner.where(name: nil).each { |partner| partner.update(name: 'Event Partner') }
    change_column_null :partners, :name, false
    change_column_null :partners, :banner_link, true
  end

  def self.down
    change_column_null :partners, :name, true
    change_column_null :partners, :banner_link, false
  end
end
