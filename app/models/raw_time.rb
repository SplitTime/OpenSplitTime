# frozen_string_literal: true

class RawTime < ApplicationRecord
  enum data_status: [:bad, :questionable, :good]
  VALID_STATUSES = [nil, data_statuses[:good], data_statuses[:questionable]]

  include Auditable
  include DataStatusMethods
  include Delegable
  include TimePointMethods
  include TimeRecordable
  include TimeZonable

  zonable_attribute :absolute_time
  has_paper_trail

  belongs_to :event_group
  belongs_to :split_time

  delegate :organization, :stewards, to: :event_group

  attribute :lap, :integer
  attribute :split_time_exists, :boolean

  attr_accessor :new_split_time
  attr_writer :effort, :event, :split

  before_validation :parameterize_split_name
  before_validation :create_sortable_bib_number
  before_validation :create_matchable_bib_number

  validates_presence_of :event_group, :split_name, :bitkey, :bib_number, :source
  validates :bib_number, length: {maximum: 6}, format: {with: /\A[\d\*]+\z/, message: 'may contain only digits and asterisks'}

  scope :with_organization_id, -> { from(select('raw_times.*, event_groups.organization_id').joins(:event_group), :raw_times) }

  def self.with_relation_ids(args = {})
    query = RawTimeQuery.with_relations(args)
    self.find_by_sql(query)
  end

  def self.search(search_text)
    return all unless search_text.present?
    bib_numbers = search_text.split(/[\s,]+/)
    where(bib_number: bib_numbers)
  end

  def clean?
    valid_status? && !split_time_exists?
  end

  def effort
    @effort = nil if matchable_bib_number.nil?
    return @effort if defined?(@effort)

    if has_effort_id?
      @effort = Effort.find(attributes['effort_id'])
    else
      @effort = Effort.joins(:event).find_by(bib_number: matchable_bib_number, events: {event_group_id: event_group_id})
    end
  end

  def effort_id
    attributes.has_key?('effort_id') ? attributes['effort_id'] : effort&.id
  end

  def has_effort_id?
    attributes['effort_id'].present?
  end

  def event
    @event = nil if matchable_bib_number.nil?
    return @event if defined?(@event)

    if has_event_id?
      @event = Event.find(attributes['event_id'])
    else
      @event = Event.joins(:efforts).find_by(event_group: event_group_id, efforts: {bib_number: matchable_bib_number})
    end
  end

  def event_id
    attributes.has_key?('event_id') ? attributes['event_id'] : event&.id
  end

  def has_event_id?
    attributes['event_id'].present?
  end

  def split
    @split = nil if matchable_bib_number.nil? ||
        (attributes.has_key?('split_id') && attributes['split_id'].nil?)
    return @split if defined?(@split)

    if attributes['split_id']
      @split = Split.find(attributes['split_id'])
    else
      rt = RawTime.where(id: self).with_relation_ids.first
      if rt&.split_id
        @split = Split.find(rt.split_id)
      else
        @split = nil
      end
    end
  end

  def split_id
    # We need to return nil if the split_id key exists and is nil
    return attributes['split_id'] if attributes.has_key?('split_id')
    split&.id
  end

  def has_split_id?
    attributes['split_id'].present?
  end

  def has_time_data?
    absolute_time.present? || entered_time.present?
  end

  private

  def create_sortable_bib_number
    self.sortable_bib_number = bib_number&.gsub(/\D/, '0').to_i
  end

  def create_matchable_bib_number
    self.matchable_bib_number = bib_number&.numeric? ? bib_number.to_i : nil
  end

  def parameterize_split_name
    self.parameterized_split_name = split_name&.parameterize
  end

  def home_time_zone
    @home_time_zone ||= attributes['home_time_zone'] || event_group.home_time_zone
  end
end
