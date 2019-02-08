class AddTopicResourceKeyToEfforts < ActiveRecord::Migration[5.2]
  def change
    add_column :efforts, :topic_resource_key, :string
    add_index :efforts, :topic_resource_key
  end
end
