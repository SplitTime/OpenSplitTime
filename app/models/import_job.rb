class ImportJob < ApplicationRecord
  belongs_to :user

  def parent_slug
    parent_type.constantize.find(parent_id).slug
  end
end
