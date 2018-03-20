# frozen_string_literal: true

class RawTime < ApplicationRecord
  include Auditable
  include LiveRawTimeMethods

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

  scope :with_effort_split_ids, -> { select('raw_times.*, efforts.id as effort_id, splits.id as split_id')
                                         .joins(event_group: {events: [:efforts, :splits]})
                                         .where('efforts.bib_number::text = raw_times.bib_number')
                                         .where('splits.parameterized_base_name = raw_times.parameterized_split_name') }

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
