# frozen_string_literal: true

class HistoricalFactAutoReconciler
  PERSONAL_ATTRIBUTES = [:first_name, :last_name, :gender, :birthdate, :email, :phone].freeze
  RESULT_KINDS = ["dns", "dnf", "finished"].freeze

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

      matching_person_id = person_id_from_effort(fact)
      matching_person_id ||= person_id_from_related_facts(fact)

      matching_person = person_from_id(matching_person_id) ||
        fact.definitive_matching_person ||
        fact.exact_matching_person

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

  # @return [Hash<Array,Struct>]
  def indexed_effort_structs
    @indexed_effort_structs ||=
      organization_efforts.struct_pluck(:person_id, :first_name, :last_name, :gender, :scheduled_start_time, :started, :finished).index_by { |struct| [struct.first_name, struct.last_name, struct.scheduled_start_time&.year] }
  end

  # @return [ActiveRecord::Relation<Effort>]
  def organization_efforts
    Effort.where(event: parent.events)
  end

  def person_from_id(matching_person_id)
    Person.find_by(id: matching_person_id)
  end

  def person_id_from_effort(fact)
    return unless fact.kind.in?(RESULT_KINDS)

    key = [fact.first_name, fact.last_name, fact.comments.to_i]
    effort = indexed_effort_structs[key]

    if effort.present?
      case fact.kind
      when "dns"
        matching_person_id = effort.person_id if !effort.started
      when "dnf"
        matching_person_id = effort.person_id if effort.started && !effort.finished
      when "finished"
        matching_person_id = effort.person_id if effort.finished
      else
        matching_person_id = nil
      end
    end
    matching_person_id
  end

  # @param [HistoricalFact] fact
  # @return [Integer, nil]
  def person_id_from_related_facts(fact)
    fact.related_facts.reconciled.pluck(:person_id).first
  end
end
