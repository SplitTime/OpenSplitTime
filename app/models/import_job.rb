class ImportJob < ApplicationRecord
  belongs_to :user
  broadcasts_to :user

  enum :status => {
    :waiting => 0,
    :processing => 1,
    :finished => 2,
    :failed => 3
  }

  STATUS_CLASSES = {
    :waiting => "text-secondary",
    :processing => "text-warning",
    :finished => "text-success",
    :failed => "text-danger",
  }

  def status_class
    return if status.nil?

    STATUS_CLASSES[status.to_sym]
  end

  def parent_slug
    parent_type.constantize.find(parent_id).slug
  end
end
