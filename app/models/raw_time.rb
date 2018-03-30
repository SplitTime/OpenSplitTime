# frozen_string_literal: true

class RawTime < ApplicationRecord
  include Auditable
  include TimeRecordable

  belongs_to :event_group
  belongs_to :split_time

  before_validation :parameterize_split_name

  validates_presence_of :event_group, :split_name, :bitkey, :bib_number, :source
  validates :bib_number, length: {maximum: 6}, format: {with: /\A[\d\*]+\z/, message: 'may contain only digits and asterisks'}
  validates_uniqueness_of :absolute_time, scope: [:event_group_id, :split_name, :bitkey, :bib_number, :source, :with_pacer, :stopped_here],
                          message: 'is an exact duplicate of an existing raw time',
                          if: Proc.new { |live_time| live_time.absolute_time.present? }
  validates_uniqueness_of :entered_time, scope: [:event_group_id, :split_name, :bitkey, :bib_number, :source, :with_pacer, :stopped_here],
                          message: 'is an exact duplicate of an existing raw time',
                          if: Proc.new { |live_time| live_time.entered_time.present? }

  scope :with_relation_ids, -> { select('raw_times.*, efforts.id as effort_id, efforts.event_id as event_id, splits.id as split_id')
                                     .joins(event_group: {events: [:efforts, :splits]})
                                     .where('efforts.bib_number::text = raw_times.bib_number')
                                     .where('splits.parameterized_base_name = raw_times.parameterized_split_name') }

  def event_id
    attributes.has_key?('event_id') ? attributes['event_id'] : effort&.event_id
  end

  def effort
    return Effort.find(attributes['effort_id']) if attributes.has_key?('effort_id')
    Effort.joins(:event).find_by(bib_number: bib_number, events: {event_group_id: event_group_id})
  end

  def effort_id
    attributes.has_key?('effort_id') ? attributes['effort_id'] : effort&.id
  end

  def split
    return Split.find(attributes['split_id']) if attributes.has_key?('split_id')
    Split.joins(course: {events: :efforts}).find_by(parameterized_base_name: parameterized_split_name,
                                                    efforts: {bib_number: bib_number},
                                                    events: {event_group_id: event_group_id})
  end

  def split_id
    attributes.has_key?('split_id') ? attributes['split_id'] : split&.id
  end

  def sub_split_kind
    SubSplit.kind(bitkey)
  end

  def sub_split_kind=(sub_split_kind)
    self.bitkey = SubSplit.bitkey(sub_split_kind.to_s)
  end

  private

  def parameterize_split_name
    self.parameterized_split_name = split_name&.parameterize
  end
end
