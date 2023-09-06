# frozen_string_literal: true

module Syncable
  extend ActiveSupport::Concern

  included do
    has_many :syncable_sources, as: :destination, class_name: "SyncableRelation", dependent: :destroy
    has_many :syncable_destinations, as: :source, class_name: "SyncableRelation", dependent: :destroy
  end
end
