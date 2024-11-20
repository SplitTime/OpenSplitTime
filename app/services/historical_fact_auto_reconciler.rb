# frozen_string_literal: true

class HistoricalFactAutoReconciler
  PERSONAL_ATTRIBUTES = [:first_name, :last_name, :gender, :birthdate, :email, :phone].freeze

  def self.reconcile(parent)
    new(parent).reconcile
  end

  def initialize(parent)
    @parent = parent
  end

  def reconcile
    historical_facts.unreconciled.find_each(batch_size: 100) do |fact|
      # In case a race condition in which a fact is reconciled by another process
      next if fact.reconciled?

      matching_person = fact.definitive_matching_person || fact.exact_matching_person

      person = if matching_person.present?
                 matching_person
               elsif fact.possible_matching_people.blank?
                 Person.new
               else
                 nil
               end

      next if person.nil?

      ::Interactors::PullAttributes.perform(fact, person, PERSONAL_ATTRIBUTES)
      ::Interactors::PullGeoAttributes.perform(fact, person)

      person.historical_facts << fact
      person.save
    end
  end

  private

  attr_reader :parent
  delegate :historical_facts, to: :parent, private: true
end
