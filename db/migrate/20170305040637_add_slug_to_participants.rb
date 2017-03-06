class AddSlugToParticipants < ActiveRecord::Migration
  def self.up
    add_column :participants, :slug, :string
    add_index :participants, :slug, unique: true
    Participant.find_each(&:save)
    change_column_null :participants, :slug, false
  end

  def self.down
    change_column_null :participants, :slug, true
    remove_index :participants, :slug
    remove_column :participants, :slug
  end
end
