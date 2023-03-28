# frozen_string_literal: true

class UserSettingsPolicy < ApplicationPolicy
  attr_reader :user

  def post_initialize(_)
  end

  def preferences?
    user.present?
  end

  def password?
    preferences?
  end

  def credentials?
    user.present?
  end

  def update?
    preferences?
  end
end
