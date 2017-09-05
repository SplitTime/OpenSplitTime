class RenameParticipantsToPeople < ActiveRecord::Migration[5.0]
  def change
    rename_table :participants, :people
    rename_column :efforts, :participant_id, :person_id
    rename_column :subscriptions, :participant_id, :person_id
  end
end
