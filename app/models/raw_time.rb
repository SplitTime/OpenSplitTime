# frozen_string_literal: true

class RawTime < ApplicationRecord
  include Auditable
  include LiveRawTimeMethods

  belongs_to :event_group
  belongs_to :split_time
  validates_presence_of :event_group, :split_name, :bitkey, :bib_number, :source
  validates :bib_number, length: {maximum: 6}, format: {with: /\A[\d\*]+\z/, message: 'may contain only digits and asterisks'}
  validates_uniqueness_of :absolute_time, scope: [:event_group_id, :split_name, :bitkey, :bib_number, :source, :with_pacer, :stopped_here],
                          message: 'is an exact duplicate of an existing raw time',
                          if: Proc.new { |live_time| live_time.absolute_time.present? }
  validates_uniqueness_of :entered_time, scope: [:event_group_id, :split_name, :bitkey, :bib_number, :source, :with_pacer, :stopped_here],
                          message: 'is an exact duplicate of an existing raw time',
                          if: Proc.new { |live_time| live_time.entered_time.present? }
end
