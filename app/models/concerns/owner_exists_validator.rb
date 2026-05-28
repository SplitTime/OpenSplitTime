class OwnerExistsValidator < ActiveModel::Validator
  def validate(record)
    return unless User.find_by(id: record.owner_id).nil?

    record.errors.add(:owner_id, "does not exist")
  end
end
