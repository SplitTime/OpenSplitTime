class AddStagingIdToEvents < ActiveRecord::Migration
  def change
    add_column :events, :staging_id, :uuid, default: 'uuid_generate_v4()'
  end
end