class LiveTime < ActiveRecord::Base
  enum source: [:internal, :api]
  include Auditable

  belongs_to :event
  belongs_to :split

end
