# frozen_string_literal: true

class ReconcilePresenter < BasePresenter
  delegate :name, :organization, :start_time_local, :available_live, :efforts, :unreconciled_efforts, :id, to: :parent

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:parent, :current_user],
                           exclusive: [:parent, :params, :current_user],
                           class: self.class)
    @parent = args[:parent]
    @params = args[:params]
    @current_user = args[:current_user]
    unreconciled_batch.each(&:suggest_close_match)
  end

  def unreconciled_batch
    @unreconciled_batch ||= parent.unreconciled_efforts.includes(split_times: :split).order(:last_name).limit(20)
  end

  def event_group
    parent.respond_to?(:event_group) ? parent.event_group : parent
  end

  def event
    parent.respond_to?(:event) ? parent.event : parent
  end

  private

  attr_reader :parent, :params, :current_user
end
