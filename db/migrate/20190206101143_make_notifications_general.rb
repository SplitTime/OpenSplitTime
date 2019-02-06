class MakeNotificationsGeneral < ActiveRecord::Migration[5.2]
  def change
    add_column :notifications, :kind, :integer
    add_column :notifications, :notice_text, :text
  end
end
