class AddPartnerableTypeAndIdToPartners < ActiveRecord::Migration[7.0]
  def up
    add_column :partners, :partnerable_type, :string
    add_column :partners, :partnerable_id, :integer

    ::Partner.all.find_each do |partner|
      partner.partnerable_type = "EventGroup"
      partner.partnerable_id = partner.event_group_id
      partner.save!
    end
  end

  def down
    remove_column :partners, :partnerable_type
    remove_column :partners, :partnerable_id
  end
end
