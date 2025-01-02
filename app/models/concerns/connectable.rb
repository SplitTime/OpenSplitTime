module Connectable
  extend ActiveSupport::Concern

  included do
    has_many :connections, as: :destination, dependent: :destroy
  end
end
