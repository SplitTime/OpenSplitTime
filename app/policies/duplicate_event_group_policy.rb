# frozen_string_literal: true

class DuplicateEventGroupPolicy < ApplicationPolicy
  attr_reader :event_group

  def post_initialize(event_group)
    @event_group = event_group
  end

  def new?
    user.authorized_to_edit?(event_group)
  end

  def create?
    user.authorized_to_edit?(event_group)
  end
end
