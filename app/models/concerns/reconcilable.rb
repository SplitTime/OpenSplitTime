# frozen_string_literal: true

module Reconcilable
  extend ActiveSupport::Concern

  def unreconciled_efforts
    efforts.where(person_id: nil)
  end
end
