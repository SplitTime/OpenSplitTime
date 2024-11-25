# frozen_string_literal: true

class OrganizationHistoricalFactsReconcilePresenter < OrganizationPresenter
  def initialize(organization, view_context)
    super
    @personal_info_hash = view_context.params[:personal_info_hash]
  end

  delegate :full_name, to: :master_fact, allow_nil: true

  def relevant_historical_facts
    historical_facts.where(personal_info_hash: personal_info_hash).order(:id)
  end

  def next_personal_info_hash
    historical_facts.unreconciled.where.not(personal_info_hash: personal_info_hash).first&.personal_info_hash
  end

  private

  attr_reader :personal_info_hash
  delegate :historical_facts, to: :organization, private: true

  def master_fact
    relevant_historical_facts.first
  end
end
