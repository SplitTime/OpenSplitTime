class AddTopicResourceKeyToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :topic_resource_key, :string
  end
end
