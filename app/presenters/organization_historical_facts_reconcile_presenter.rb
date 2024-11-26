# frozen_string_literal: true

class OrganizationHistoricalFactsReconcilePresenter < OrganizationPresenter
  # @param [Organization] organization
  # @param [ActionView::Base] view_context
  def initialize(organization, view_context)
    super
    @personal_info_hash = view_context.params[:personal_info_hash]
  end

  attr_reader :personal_info_hash
  delegate :bio, :email, :flexible_geolocation, :full_name, :phone, :possible_matching_people, to: :master_fact, allow_nil: true

  # @return [ActiveRecord::Relation<HistoricalFact>]
  def relevant_historical_facts
    historical_facts.where(personal_info_hash: personal_info_hash)
  end

  # @return [String, nil]
  def previous_personal_info_hash
    historical_facts.unreconciled.where("id < ?", lowest_relevant_historical_fact_id).order(id: :desc).first&.personal_info_hash
  end

  # @return [String, nil]
  def next_personal_info_hash
    historical_facts.unreconciled.where("id > ?", highest_relevant_historical_fact_id).order(id: :asc).first&.personal_info_hash
  end

  private

  delegate :historical_facts, to: :organization, private: true

  # @return [Integer, nil]
  def highest_relevant_historical_fact_id
    relevant_historical_fact_ids.last
  end

  # @return [Integer, nil]
  def lowest_relevant_historical_fact_id
    relevant_historical_fact_ids.first
  end

  # @return [HistoricalFact, nil]
  def master_fact
    relevant_historical_facts.first
  end

  # @return [Array<Integer>]
  def relevant_historical_fact_ids
    relevant_historical_facts.order(id: :asc).ids
  end
end
