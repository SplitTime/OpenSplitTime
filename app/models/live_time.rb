class LiveTime < ActiveRecord::Base
  enum source: [:internal, :generic_api]
  include Auditable

  belongs_to :event
  belongs_to :split
end
