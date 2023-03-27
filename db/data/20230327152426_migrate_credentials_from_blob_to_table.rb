# frozen_string_literal: true

class MigrateCredentialsFromBlobToTable < ActiveRecord::Migration[7.0]
  def up
    User.find_each do |user|
      next if user.credentials.blank?

      user.credentials.each do |service_identifier, credential_hash|
        credential_hash.each do |credential_key, credential_value|
          user.credentials.find_or_create_by!(
            service_identifier: service_identifier,
            key: credential_key,
            value: credential_value
          )
        end
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
