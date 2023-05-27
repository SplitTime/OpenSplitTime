# frozen_string_literal: true

module Auditable
  extend ActiveSupport::Concern

  included do
    # Assigns created_by_id upon included Class initialization
    before_validation :add_created_by

    scope :created_by, -> (user_id) { where(created_by: user_id) }
  end

  private

  def add_created_by
    if User.current
      self.created_by ||= User.current.id
    elsif self.created_by.nil? && Rails.env != "test"
      warn "WARNING: #{self.class} was validated with no user assigned to created_by, and Auditable " +
           "did not assign one because the current User object was not available at the time of validation."
    end
  end
end
