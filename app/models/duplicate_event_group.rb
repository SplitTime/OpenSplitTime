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
      self.new_event_group = existing_event_group.dup
      new_event_group.assign_attributes(name: new_name, concealed: true, available_live: false)
      new_event_group.events = existing_event_group.events.map(&:dup)
      new_event_group.events.each do |event|
        event.assign_attributes(start_time: event.start_time + offset, historical_name: nil, beacon_url: nil)
      end
      new_event_group.save
    end
    self
  end

  private

  attr_writer :new_event_group

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
