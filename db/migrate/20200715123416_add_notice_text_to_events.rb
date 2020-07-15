class AddNoticeTextToEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :notice_text, :string
  end
end
