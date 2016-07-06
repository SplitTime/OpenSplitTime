class AddUrlFieldsToEfforts < ActiveRecord::Migration
  def change
    add_column :efforts, :beacon_url, :string
    add_column :efforts, :report_url, :string
  end
end
