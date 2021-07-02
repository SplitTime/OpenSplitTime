class ImportJob < ApplicationRecord
  belongs_to :user

  enum :status => {
    :waiting => 0,
    :processing => 1,
    :finished => 2,
    :failed => 3
  }

  def parent_slug
    parent_type.constantize.find(parent_id).slug
  end
end
