class ChangeCredentialsColumnNames < ActiveRecord::Migration[7.0]
  def change
    rename_column :credentials, :service, :service_identifier
  end
end
