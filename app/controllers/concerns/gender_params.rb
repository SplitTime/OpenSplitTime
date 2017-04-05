module GenderParams
  def self.prepare(gender_params)
    gender_string = gender_params.presence || 'male,female'
    gender_string.split(',').map { |param| param.numeric? ? param.to_i : Effort.genders[param] }
  end
end
