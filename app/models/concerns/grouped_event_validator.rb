# frozen_string_literal: true

class GroupedEventValidator < ActiveModel::Validator
  def validate(event)
    @event = event
    return unless event_group
    @analyzer = EventGroupSplitAnalyzer.new(event_group)
    validate_bibs
    validate_split_locations
  end

  private

  attr_reader :event, :analyzer
  delegate :events, :incompatible_locations, to: :analyzer

  def validate_bibs
    efforts_with_bibs = Effort.where(event: event_group.events).where.not(bib_number: nil).select(:bib_number)
    if efforts_with_bibs.size != efforts_with_bibs.distinct.size
      duplicate_bib_numbers = efforts_with_bibs.pluck(:bib_number).count_by(&:itself)
                                  .select { |_, count| count > 1 }.keys.uniq.sort
      dup_size = duplicate_bib_numbers.size
      event.errors.add(:base, "Bib #{'number'.pluralize(dup_size)} #{duplicate_bib_numbers.to_sentence} #{'is'.pluralize(dup_size)} duplicated within the event group")
    end
  end

  def validate_split_locations
    if incompatible_locations.present?
      size = incompatible_locations.size
      locations = incompatible_locations.map(&:titleize).to_sentence
      event.errors.add(:base, "#{'Location'.pluralize(size)} #{locations} #{'is'.pluralize(size)} " +
          "incompatible within the event group. Splits with duplicate names must have the same locations. ")
    end
  end

  def event_group
    EventGroup.where(id: event.event_group).includes(events: :splits).first
  end
end
