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
    else
      warn "WARNING: No user id was assigned to #{self.class} #{self.id} " +
               'because the current User object was not available at the time of creation.'
    end
  end

  # Updates current instance's updated_by if current_user is not nil and is not destroyed.
  def update_updated_by
    if User.current and not destroyed?
      self.updated_by = User.current.id
    else
      warn "WARNING: No user id was updated for #{self.class} #{self.id} " +
               'because the current User object was not available at the time of creation.'
    end
  end
end