# frozen_string_literal: true

class OwnerExistsValidator < ActiveModel::Validator
  def validate(record)
    if record.owner_id == Organization::NOT_FOUND_OWNER_ID || User.find_by(id: record.owner_id).nil?
      record.errors.add(:owner_id, 'does not exist')
    end
  end
end
