# frozen_string_literal: true

class BirthdateValidator < ActiveModel::Validator
  def validate(record)
    if record.birthdate.present? && (record.birthdate < '1900-01-01'.to_date)
      record.errors.add(:birthdate, "can't be before 1900")
    end
    if record.birthdate.present? && (record.birthdate >= Date.today)
      record.errors.add(:birthdate, "can't be today or in the future")
    end
  end
end
