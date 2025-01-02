class LotteryEntrantUniqueValidator < ActiveModel::Validator
  def validate(entrant)
    return unless entrant.division.present? && entrant.lottery.present?

    divisions = entrant.lottery.divisions
    existing_entrant = LotteryEntrant.where(division: divisions, first_name: entrant.first_name, last_name: entrant.last_name, birthdate: entrant.birthdate)
    return unless existing_entrant.present?

    conflicting_entrant = if entrant.persisted?
                            existing_entrant.where.not(id: entrant.id)
                          else
                            existing_entrant
                          end

    if conflicting_entrant.present?
      entrant.errors.add(:base, "#{entrant.full_name} has already been entered in #{entrant.division.name}")
    end
  end
end
