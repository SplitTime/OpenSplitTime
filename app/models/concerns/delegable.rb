# frozen_string_literal: true

# The including class must contain an `organization_id` attribute and a
# `concealed` attribute *or* must override the :with_policy_scope_attributes
# scope using joins to put an `organization_id` attribute and a `concealed`
# attribute on scoped records, for example:
#
# scope :with_policy_scope_attributes, -> do
#   from(select('events.*, event_groups.organization_id, event_groups.concealed').joins(:event_group), :events)
# end
#
# The including class must also respond to `organization`.
#
module Delegable
  extend ActiveSupport::Concern

  included do
    scope :with_policy_scope_attributes, ->{ all }
    scope :owned_by, ->(user) { with_policy_scope_attributes.where("#{table_name}.organization_id in (?)", user.owned_organization_ids) }
    scope :visible, -> { with_policy_scope_attributes.where("#{table_name}.concealed is not true") }

    scope :delegated_to, ->(user) do
      with_policy_scope_attributes
        .where("#{table_name}.organization_id in (?)", user.delegated_organization_ids)
    end

    scope :visible_or_delegated_to, ->(user) do
      with_policy_scope_attributes
        .where("#{table_name}.concealed is not true or #{table_name}.organization_id in (?)", user.delegated_organization_ids)
    end
  end

  delegate :stewards, to: :organization

  def owner_id
    organization.created_by
  end
end
