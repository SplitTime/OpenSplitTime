class AddTopicResourceKeyToParticipants < ActiveRecord::Migration
  def self.up
    add_column :participants, :topic_resource_key, :string
    add_index :participants, :topic_resource_key, unique: true
    print "Generating topics for all #{Participant.count} participants in the database.\n"
    sns_client = SnsClientFactory.client
    Participant.all.each do |participant|
      participant.topic_resource_key = SnsTopicManager.generate(participant: participant, sns_client: sns_client)
      participant.save!
    end
    print "\nFinished generating topics.\n"
  end

  def self.down
    print "Deleting topics for all #{Participant.count} participants in the database.\n"
    sns_client = SnsClientFactory.client
    Participant.all.each do |participant|
      SnsTopicManager.delete(participant: participant, sns_client: sns_client)
    end
    print "\nFinished deleting topics.\n"
    remove_index :participants, :topic_resource_key
    remove_column :participants, :topic_resource_key
  end
end
