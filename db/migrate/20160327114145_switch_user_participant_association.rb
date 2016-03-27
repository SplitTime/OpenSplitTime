class SwitchUserParticipantAssociation < ActiveRecord::Migration
  def change
    remove_column :users, :participant_id, :integer
    add_reference :participants, :user, index: true
    add_foreign_key :participants, :users
  end
end
