module GenderParams
  def self.prepare(gender_params)
    gender_enums = gender_params.to_s.split(',').map { |param| param.numeric? ? param.to_i : Effort.genders[param] }
    gender_enums.compact.presence || Effort.genders.values
  end
end
