# frozen_string_literal: true

require "connectors/service"

class Credential < ApplicationRecord
  belongs_to :user

  encrypts :value

  validates :service_identifier, :key, :value, presence: true
  validates :key,
            if: :key?,
            uniqueness: {
              scope: [:user, :service_identifier],
              message: ->(record, _) do
                "Duplicate key #{record.key} for user #{record.user_id} and service_identifier #{record.service_identifier}"
              end
            }
  validates :service_identifier,
            if: :service_identifier?,
            inclusion: {
              in: Connectors::Service::IDENTIFIERS,
              message: ->(record, _) do
                "Invalid service_identifier #{record.service_identifier}"
              end
            }
  validates :key,
            if: :key?,
            inclusion: {
              in: ->(record) do
                Connectors::Service::BY_IDENTIFIER[record.service_identifier]&.credential_keys || []
              end,
              message: ->(record, _) do
                "Invalid key #{record.key} for service_identifier #{record.service_identifier}"
              end
            }

  scope :for_service, ->(service_identifier) { where(service_identifier: service_identifier) }

  # @param [String,Symbol] service_identifier
  # @param [String,Symbol] key
  # @return [String, nil]
  def self.fetch(service_identifier, key)
    records = where(service_identifier: service_identifier, key: key).limit(2).to_a
    raise ActiveRecord::RecordNotUnique, "Multiple records found for service_identifier #{service_identifier} and key #{key}" if records.many?

    records.first&.value
  end
end
