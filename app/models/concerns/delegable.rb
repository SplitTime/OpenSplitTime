# frozen_string_literal: true

module Delegable
  extend ActiveSupport::Concern

  included do
    scope :delegated, -> (user_id) { where('stewardships.user_id = ? OR organizations.created_by = ?', user_id, user_id) }
  end

  def owner_id
    organization.created_by
  end
end
