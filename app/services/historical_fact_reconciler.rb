class HistoricalFactReconciler
  PERSONAL_ATTRIBUTES = [:first_name, :last_name, :gender, :birthdate, :email, :phone].freeze

  def self.reconcile(parent, personal_info_hash:, person_id:)
    new(parent, personal_info_hash: personal_info_hash, person_id: person_id).reconcile
  end

  def initialize(parent, personal_info_hash:, person_id:)
    @parent = parent
    @personal_info_hash = personal_info_hash
    @person_id = person_id
  end

  def reconcile
    person = Person.new if person_id == "new"
    person ||= Person.find_by(id: person_id)
    return if person.nil?

    historical_facts.each do |fact|
      ::Interactors::PullAttributes.perform(fact, person, PERSONAL_ATTRIBUTES)
      ::Interactors::PullGeoAttributes.perform(fact, person)

      person.historical_facts << fact
      person.save!
    end
  end

  private

  attr_reader :parent, :personal_info_hash, :person_id

  def historical_facts
    parent.historical_facts.where(personal_info_hash: personal_info_hash)
  end
end
