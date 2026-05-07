class AddFieldMappingsToConnections < ActiveRecord::Migration[8.1]
  def change
    add_column :connections, :field_mappings, :jsonb, default: [], null: false
  end
end
