# frozen_string_literal: true

class DuplicateEventGroup
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :existing_id, :integer
  attribute :new_name, :string
  attribute :new_start_date, :date
  attr_reader :new_event_group

  validates_presence_of :existing_event_group, :new_name, :new_start_date
  validate :merge_event_group_errors, if: :new_event_group

  def self.create(params)
    new(params).create
  end

  delegate :name, :organization, :to_param, to: :existing_event_group

  def create
    if valid?
      duplicate_event_group
      if new_event_group.save
        conform_splits
      end
    end
    self
  end

  private

  attr_writer :new_event_group

  def duplicate_event_group
    self.new_event_group = existing_event_group.dup
    new_event_group.assign_attributes(name: new_name, concealed: true, available_live: false)
    existing_event_group.events.each do |existing_event|
      new_event = existing_event.dup
      new_event.assign_attributes(start_time: existing_event.start_time + offset, historical_name: nil, beacon_url: nil)
      new_event_group.events << new_event
    end
  end

  # Saving the events will attach all course splits to each, so we need to
  # conform splits by deleting those that are not included in the original.
  def conform_splits
    new_event_group.events.each do |new_event|
      existing_event = existing_event_group.events.find { |existing_event| existing_event.short_name == new_event.short_name }
      new_event.aid_stations.each do |aid_station|
        aid_station.destroy unless aid_station.split_id.in?(existing_event.split_ids)
      end
    end
  end

  def offset
    @offset ||= (new_start_date.to_date - existing_event_group.start_time_local.to_date).days
  end

  def existing_event_group
    @existing_event_group ||= EventGroup.includes(:events).where(id: existing_id).first
  end

  def merge_event_group_errors
    errors.merge!(new_event_group.errors)
  end
end
