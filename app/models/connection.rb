# frozen_string_literal: true

class Connection < ApplicationRecord
  belongs_to :destination, polymorphic: true

  scope :from_service, ->(service_identifier) { where(service_identifier: service_identifier) }
end
