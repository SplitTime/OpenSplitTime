# frozen_string_literal: true

class Notification < ApplicationRecord
  include Auditable

  self.ignored_columns = %w[updated_by]

  enum kind: [:participation, :progress]

  belongs_to :effort
  has_one :event, through: :effort
end
