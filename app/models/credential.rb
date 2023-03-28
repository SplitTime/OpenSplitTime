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
              message: ->(object, _) do
                "Duplicate key #{object.key} for user #{object.user_id} and service_identifier #{object.service_identifier}"
              end
            }
  validates :service_identifier,
            if: :service_identifier?,
            inclusion: {
              in: Connectors::Service::IDENTIFIERS,
              message: ->(object, _) do
                "Invalid service_identifier #{object.service_identifier}"
              end
            }

  scope :for_service, ->(service_identifier) { where(service_identifier: service_identifier) }

  def self.fetch(service_identifier, key)
    find_by(service_identifier: service_identifier, key: key)&.value
  end
end
