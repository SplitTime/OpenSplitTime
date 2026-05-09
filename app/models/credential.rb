require "connectors/service"

class Credential < ApplicationRecord
  belongs_to :user

  encrypts :value

  def value
    super
  rescue ActiveRecord::Encryption::Errors::Decryption
    nil
  end

  validates :service_identifier, :key, :value, presence: true
  validates :key,
            if: :key?,
            uniqueness: {
              scope: [:user, :service_identifier],
              message: lambda do |record, _|
                "Duplicate key #{record.key} for user #{record.user_id} " \
                  "and service_identifier #{record.service_identifier}"
              end
            }
  validates :service_identifier,
            if: :service_identifier?,
            inclusion: {
              in: Connectors::Service::IDENTIFIERS,
              message: lambda do |record, _|
                "Invalid service_identifier #{record.service_identifier}"
              end
            }
  validates :key,
            if: :key?,
            inclusion: {
              in: lambda do |record|
                Connectors::Service::BY_IDENTIFIER[record.service_identifier]&.credential_keys || []
              end,
              message: lambda do |record, _|
                "Invalid key #{record.key} for service_identifier #{record.service_identifier}"
              end
            }

  scope :for_service, ->(service_identifier) { where(service_identifier: service_identifier) }

  # This method is meant to be scoped to the credentials of a single user, e.g.
  # user.credentials.fetch("runsignup", "api_key")

  # @param [String,Symbol] service_identifier
  # @param [String,Symbol] key
  # @return [String, nil]
  def self.fetch(service_identifier, key)
    records = where(service_identifier: service_identifier, key: key).limit(2).to_a
    if records.many?
      raise ActiveRecord::RecordNotUnique,
            "Multiple records found for service_identifier #{service_identifier} and key #{key}"
    end

    records.first&.value
  end

  # Allows us to use a Credential object in dom_id, for example,
  # dom_id(Credential.new(service_identifier: "foo", key: "bar")) => "credential_foo_bar"
  def to_key
    [service_identifier, key]
  end
end
