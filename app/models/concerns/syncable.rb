# frozen_string_literal: true

module Syncable
  extend ActiveSupport::Concern

  included do
    has_many :syncable_sources, as: :destination, class_name: "SyncableRelation", dependent: :destroy
  end

  def syncable_destinations(destination_name = nil)
    syncable_relations = ::SyncableRelation.where(source_name: "internal", source_type: self.class.name, source_id: id)
    syncable_relations = syncable_relations.where(destination_name: destination_name) if destination_name.present?
    syncable_relations
  end
end
