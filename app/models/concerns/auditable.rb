module Auditable
  extend ActiveSupport::Concern

  included do
    # Assigns created_by_id and updated_by_id upon included Class initialization
    before_validation :add_created_by_and_updated_by

    # Updates updated_by_id for the current instance
    after_save :update_updated_by
  end

  private

  def add_created_by_and_updated_by
    self.created_by ||= User.current.id if User.current
    self.updated_by = User.current.id if User.current
  end

  # Updates current instance's updated_by if current_user is not nil and is not destroyed.
  def update_updated_by
    self.updated_by = User.current.id if User.current and not destroyed?
  end
end