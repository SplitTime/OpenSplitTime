# frozen_string_literal: true

module Syncable
  extend ActiveSupport::Concern

  def syncable_destinations(destination_name = nil)
    syncable_relations = ::SyncableRelation.where(source_name: "internal", source_type: self.class.name, source_id: id)
    syncable_relations = syncable_relations.where(destination_name: destination_name) if destination_name.present?
    syncable_relations
  end

  def syncable_sources(source_name = nil)
    syncable_relations = ::SyncableRelation.where(destination_name: "internal", destination_type: self.class.name, destination_id: id)
    syncable_relations = syncable_relations.where(source_name: source_name) if source_name.present?
    syncable_relations
  end
end
