# frozen_string_literal: true

class ImportJob < ApplicationRecord
  belongs_to :user
  broadcasts_to :user

  has_one_attached :file

  attribute :row_count, :default => 0
  attribute :success_count, :default => 0
  attribute :failure_count, :default => 0

  enum :status => {
    :waiting => 0,
    :extracting => 1,
    :transforming => 2,
    :loading => 3,
    :finished => 4,
    :failed => 5
  }

  validates :file, size: {less_than: 10.megabytes}

  def elapsed_time
    return unless started_at.present?

    (::Time.current - started_at).to_i
  end

  def parent_slug
    parent_type.constantize.find(parent_id).slug
  end

  def start!
    update(started_at: ::Time.current)
  end
end
