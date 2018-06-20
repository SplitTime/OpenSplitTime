# frozen_string_literal: true

class RawTime < ApplicationRecord
  enum data_status: [:bad, :questionable, :good]

  include Auditable
  include TimeRecordable

  belongs_to :event_group
  belongs_to :split_time

  before_validation :parameterize_split_name
  before_validation :create_sortable_bib_number

  validates_presence_of :event_group, :split_name, :bitkey, :bib_number, :source
  validates :bib_number, length: {maximum: 6}, format: {with: /\A[\d\*]+\z/, message: 'may contain only digits and asterisks'}
  validates_uniqueness_of :absolute_time, scope: [:event_group_id, :split_name, :bitkey, :bib_number, :source, :with_pacer, :stopped_here],
                          message: 'is an exact duplicate of an existing raw time',
                          if: Proc.new { |live_time| live_time.absolute_time.present? }
  validates_uniqueness_of :entered_time, scope: [:event_group_id, :split_name, :bitkey, :bib_number, :source, :with_pacer, :stopped_here],
                          message: 'is an exact duplicate of an existing raw time',
                          if: Proc.new { |live_time| live_time.entered_time.present? }

  def self.with_relation_ids(args = {})
    query = RawTimeQuery.with_relations(args)
    self.find_by_sql(query)
  end

  def self.search(search_text)
    return all unless search_text.present?
    bib_numbers = search_text.split(/[\s,]+/)
    where(bib_number: bib_numbers)
  end

  attr_accessor :existing_time_count, :lap
  attr_writer :effort, :event, :split

  def effort
    @effort = nil if bib_number.nil? || bib_number.include?('*')
    return @effort if defined?(@effort)

    if attributes['effort_id']
      @effort = Effort.find(attributes['effort_id'])
    else
      @effort = Effort.joins(:event).find_by(bib_number: bib_number, events: {event_group_id: event_group_id})
    end
  end

  def effort_id
    attributes['effort_id'] || effort&.id
  end
  
  def has_effort_id?
    attributes['effort_id'].present?
  end

  def event
    @event = nil if bib_number.nil? || bib_number.include?('*')
    return @event if defined?(@event)

    if attributes['event_id']
      @event = Event.find(attributes['event_id'])
    else
      @event = Event.joins(:efforts).find_by(event_group: event_group_id, efforts: {bib_number: bib_number})
    end
  end

  def event_id
    attributes['event_id'] || event&.id
  end

  def has_event_id?
    attributes['event_id'].present?
  end

  def split
    @split = nil if bib_number.nil? || bib_number.include?('*')
    return @split if defined?(@split)

    if attributes['split_id']
      @split = Split.find(attributes['split_id'])
    else
      @split = Split.joins(course: {events: :efforts}).find_by(parameterized_base_name: parameterized_split_name,
                                                               efforts: {bib_number: bib_number},
                                                               events: {event_group_id: event_group_id})
    end
  end

  def split_id
    attributes['split_id'] || split&.id
  end

  def has_split_id?
    attributes['split_id'].present?
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
