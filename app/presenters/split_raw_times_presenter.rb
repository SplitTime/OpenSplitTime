# frozen_string_literal: true

class SplitRawTimesPresenter < BasePresenter
  include SplitAnalyzable

  attr_reader :event_group, :parameterized_split_name
  delegate :name, :organization, :events, :home_time_zone, :available_live, :multiple_events?, :single_lap?, to: :event_group
  delegate :podium_template, to: :event

  def initialize(event_group, params, current_user)
    @event_group = event_group
    @parameterized_split_name = params[:parameterized_split_name] || parameterized_split_names.first
    @params = params
    @current_user = current_user
  end

  def bib_rows
    @bib_rows ||= EventGroupQuery.bib_sub_split_rows(event_group: event_group, split_name: split_name,
                                                     bitkey: bitkey, sort: params[:sort_hash])
  end

  def sources
    @sources ||= bib_rows.flat_map(&:raw_times).map(&:source_text).uniq.sort
  end

  def sub_split_kind
    param_kind = (params[:sub_split_kind] || 'in').parameterize
    sub_split_kinds.include?(param_kind) ? param_kind : 'in'
  end

  def sub_split_kinds
    @sub_split_kinds ||= splits.flat_map(&:sub_split_kinds).map(&:parameterize).uniq
  end

  def event
    events.first
  end

  private

  attr_reader :params, :current_user

  def splits
    event_group.events.flat_map(&:splits).select { |split| split.parameterized_base_name == parameterized_split_name }
  end

  def bitkey
    @bitkey ||= SubSplit.bitkey(sub_split_kind)
  end

  def universal_bib_row_attributes
    {single_lap: single_lap?}
  end
end
