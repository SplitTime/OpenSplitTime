class MakeNotificationsGeneral < ActiveRecord::Migration[5.2]
  def change
    add_column :notifications, :kind, :integer
    add_column :notifications, :topic_resource_key, :string
    add_column :notifications, :subject, :string
    add_column :notifications, :notice_text, :text
  end
end
