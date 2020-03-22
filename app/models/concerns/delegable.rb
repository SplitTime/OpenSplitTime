# frozen_string_literal: true

# The including class must contain an organization_id attribute *or*
# must override the :with_organization_id scope using joins to put an
# organization_id attribute on returned records, for example:
#
# scope :with_organization_id, -> { from(select('events.*, event_groups.organization_id').joins(:event_group), :events) }
#
module Delegable
  extend ActiveSupport::Concern

  included do
    scope :with_organization_id, -> { all }
    scope :owned_by, -> (user) { with_organization_id.where("#{table_name}.organization_id in (?)", user.owned_organization_ids) }
    scope :delegated_to, ->(user) do
      with_organization_id
        .where("#{table_name}.organization_id in (?)", user.delegated_organization_ids)
    end

    scope :visible_or_delegated_to, ->(user) do
      with_organization_id
        .where("#{table_name}.concealed is not true or #{table_name}.organization_id in (?)", user.delegated_organization_ids)
    end
  end

  delegate :stewards, to: :organization

  def owner_id
    organization.created_by
  end
end
