# frozen_string_literal: true

class ImportJob < ApplicationRecord
  belongs_to :user
  broadcasts_to :user, inserts_by: :prepend

  has_one_attached :file

  scope :most_recent_first, -> { reorder(created_at: :desc) }

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

  validates_presence_of :parent_type, :parent_id, :format
  validates :file, presence: true, size: {less_than: 10.megabytes}

  def parent
    @parent ||= parent_type.constantize.find(parent_id)
  end

  def parent_name
    parent.name
  end

  def resources_for_path
    case parent_type
    when "Lottery"
      [parent.organization, parent]
    else
      [parent]
    end
  end

  def set_elapsed_time!
    return unless persisted? && started_at.present?

    update_column(:elapsed_time, Time.current - started_at)
  end

  def start!
    update(started_at: ::Time.current)
  end
end
