# frozen_string_literal: true

module Auditable
  extend ActiveSupport::Concern

  included do
    # Assigns created_by_id and updated_by_id upon included Class initialization
    before_validation :add_created_by_and_updated_by

    # Updates updated_by_id for the current instance
    after_save :update_updated_by

    scope :created_by, -> (user_id) { where(created_by: user_id) }
  end

  private

  def add_created_by_and_updated_by
    if User.current
      self.created_by ||= User.current.id
      self.updated_by = User.current.id
    elsif self.created_by.nil? && Rails.env != 'test'
      warn "WARNING: #{self.class} was validated with no user assigned to created_by, and Auditable " +
               'did not assign one because the current User object was not available at the time of validation.'
    end
  end

  # Updates current instance's updated_by if current_user is not nil and is not destroyed.
  def update_updated_by
    self.updated_by = User.current.id if User.current and not destroyed?
  end
end
