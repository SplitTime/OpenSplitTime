# frozen_string_literal: true

class ImportJob < ApplicationRecord
  belongs_to :user
  broadcasts_to :user, inserts_by: :prepend

  has_one_attached :file

  scope :most_recent_first, -> { reorder(created_at: :desc) }
  scope :owned_by, ->(user) { where(user: user) }

  attribute :row_count, default: 0
  attribute :success_count, default: 0
  attribute :failure_count, default: 0

  enum status: {
    waiting: 0,
    extracting: 1,
    transforming: 2,
    loading: 3,
    finished: 4,
    failed: 5
  }

  validates_presence_of :parent_type, :parent_id, :format
  validates :file,
            attached: true,
            size: {less_than: 1.megabyte},
            content_type: {in: %w[text/csv text/plain], message: "must be a CSV file"}

  alias_attribute :owner_id, :user_id

  def parent
    @parent ||= parent_type.constantize.find_by(id: parent_id)
  end

  def parent_name
    parent.name
  end

  def parsed_errors
    JSON.parse(error_message || "[\"None\"]")
  end

  def resources_for_path
    return unless parent.present?

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
