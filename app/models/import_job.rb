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

  validates :parent_type, :format, presence: true
  # File-attachment validations only apply when files are actually attached.
  # Sync-from-external-service ImportJobs (where format is a Connectors::Service
  # identifier) carry no files; only file-import ImportJobs do.
  validates :files,
            content_type: { in: %w[text/csv text/plain], message: "must be a CSV file" },
            size: { less_than: 1.megabyte, message: "must be less than 1 MB" },
            if: -> { files.attached? }

  alias_attribute :owner_id, :user_id

  # External-service sync ImportJobs additionally broadcast their status to a
  # sync-specific target so the connection management page can render live
  # progress alongside (or instead of) the import_jobs index row.
  after_update_commit :broadcast_sync_status, if: :external_service_sync?

  def parent_name
    parent.name
  end

  def parent_path
    return if parent.blank?

    return sync_parent_path if external_service_sync?

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
      raise "Unknown parent type #{parent_type} for import job #{id}"
    end
  end

  def external_service_sync?
    ::Connectors::Service::IDENTIFIERS.include?(format)
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

  private

  def sync_parent_path
    event_group = parent_type == "EventGroup" ? parent : parent.event_group
    ::Rails.application.routes.url_helpers.event_group_connect_service_path(event_group, format)
  end

  def broadcast_sync_status
    broadcast_replace_to(
      user,
      target: ActionView::RecordIdentifier.dom_id(self, :sync_status),
      partial: "events/connectors/services/sync_status",
      locals: { import_job: self },
    )
  end
end
