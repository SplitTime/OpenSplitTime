# frozen_string_literal: true

class SyncableRelation < ApplicationRecord
  belongs_to :destination, polymorphic: true
end
