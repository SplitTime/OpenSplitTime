class RemoveEventGroupFromPartners < ActiveRecord::Migration[7.0]
  def change
    remove_reference :partners, :event_group, null: false
  end
end
