# frozen_string_literal: true

module Connectable
  extend ActiveSupport::Concern

  included do
    has_many :connections, as: :source, dependent: :destroy
  end
end
