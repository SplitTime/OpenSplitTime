# frozen_string_literal: true

# This module is for classes that need a :visible scope but do not have
# a `concealed` attribute directly on the table, but instead inherit
# their `concealed` status from a parent or grandparent record.
#
module DelegatedConcealable
  extend ActiveSupport::Concern

  included do
    scope :visible, -> { with_policy_scope_attributes.where("#{table_name}.concealed is not true") }
  end
end
