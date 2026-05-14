class RemoveTopicResourceKeyFromPeople < ActiveRecord::Migration[8.1]
  def change
    remove_column :people, :topic_resource_key, :string
  end
end
