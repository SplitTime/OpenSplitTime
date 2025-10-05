class ImportJob < ApplicationRecord
  belongs_to :user
  belongs_to :parent, polymorphic: true
  broadcasts_to :user, inserts_by: :prepend

  has_many_attached :files

  scope :most_recent_first, -> { reorder(created_at: :desc) }
  scope :owned_by, ->(user) { where(user: user) }

  attribute :row_count, default: 0
  attribute :succeeded_count, default: 0
  attribute :failed_count, default: 0
  attribute :ignored_count, default: 0

  enum :status, {
    waiting: 0,
    extracting: 1,
    transforming: 2,
    loading: 3,
    finished: 4,
    failed: 5
  }

  validates_presence_of :parent_type, :parent_id, :format
  validates :files,
            size: { less_than: 1.megabyte },
            content_type: { in: %w[text/csv text/plain], message: "must be a CSV file" }

  alias_attribute :owner_id, :user_id

  def parent_name
    parent.name
  end

  def parent_path
    return unless parent.present?

    case parent_type
    when "Organization"
      ::Rails.application.routes.url_helpers.organization_historical_facts_path(parent)
    when "Lottery"
      ::Rails.application.routes.url_helpers.setup_organization_lottery_path(parent.organization, parent)
    when "EventGroup"
      ::Rails.application.routes.url_helpers.entrants_event_group_path(parent)
    when "Event"
      if format == "event_course_splits"
        ::Rails.application.routes.url_helpers.setup_course_event_group_event_path(parent.event_group, parent)
      else
        ::Rails.application.routes.url_helpers.entrants_event_group_path(parent.event_group)
      end
    else
      raise RuntimeError, "Unknown parent type #{parent_type} for import job #{id}"
    end
  end

  def parsed_errors
    JSON.parse(error_message || "[\"None\"]")
  end

  def set_elapsed_time!
    return unless persisted? && started_at.present?

    update_column(:elapsed_time, Time.current - started_at)
  end

  def start!
    update(started_at: ::Time.current)
  end
end
