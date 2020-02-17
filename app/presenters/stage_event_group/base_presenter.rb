# frozen_string_literal: true

class StageEventGroup::BasePresenter < BasePresenter
  include ActiveModel::Model
  include ActiveModel::Attributes
  include UnitConversions
  validates_presence_of :event_group
  validates_presence_of :params
  validates_presence_of :current_user

  attr_reader :event_group
  delegate :name, :organization, :organization_name, :events, :ordered_events, :concealed?, :to_param, to: :event_group
  delegate :pref_distance_unit, :pref_elevation_unit, to: :current_user

  def initialize(attributes)
    @event_group = attributes[:event_group]
    @params = attributes[:params]
    @current_user = attributes[:current_user]
    post_initialize
  end

  def current_step
    raise NotImplementedError, "A subclass of #{self.class.name} must implement a current_step method."
  end

  private

  attr_reader :params, :current_user

  def event_from_id
    return nil unless event_id.present?
    event_group.events.find(event_id)
  end

  def event_id
    params.has_key?(:event) ? params.dig(:event, :id) : ordered_events.first&.id
  end

  def post_initialize
    raise NotImplementedError, "A subclass of #{self.class.name} must implement a post_initialize method."
  end
end
