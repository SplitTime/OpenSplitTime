class EffortImportDataPreparer

  def initialize(input_row, schema_array)
    @input_row = input_row
    @schema_array = schema_array
    @schema_map = schema_array.zip(input_row).to_h
    prepare_row_effort_data
  end


  def output_row
    schema_array.map { |attribute| schema_map[attribute] } # Preserves input order
  end

  private

  GENDERS = {'m' => 'male',
             'f' => 'female'}

  attr_reader :input_row, :schema_array, :schema_map
  attr_writer :output_row

  def prepare_row_effort_data
    schema_map[:country_code] = prepare_country_data
    schema_map[:state_code] = prepare_state_data
    schema_map[:gender] = prepare_gender_data
    schema_map[:birthdate] = prepare_birthdate_data
  end

  def prepare_country_data
    country_data = schema_map[:country_code].to_s.downcase.strip
    country = Carmen::Country.coded(country_data) || Carmen::Country.named(country_data)
    country ? country.code : find_country_code_by_nickname(country_data)
  end

  def find_country_code_by_nickname(country_data)
    return nil if country_data.blank?
    country_code = I18n.t("nicknames.#{country_data}")
    country_code.include?('translation missing') ? nil : country_code
  end

  def prepare_state_data
    state_data = schema_map[:state_code].to_s.strip
    return nil if state_data.blank?
    country = Carmen::Country.coded(schema_map[:country_code])
    return state_data unless country && country.subregions?
    subregion = country.subregions.coded(state_data) || country.subregions.named(state_data)
    subregion ? subregion.code : state_data
  end

  def prepare_gender_data
    GENDERS[schema_map[:gender].to_s.downcase.strip.first]
  end

  def prepare_birthdate_data
    birthdate_data = schema_map[:birthdate]
    case
    when birthdate_data.blank?
      nil
    when birthdate_data.is_a?(Date)
      birthdate_data
    when birthdate_data.is_a?(String)
      begin
        Date.parse(birthdate_data)
      rescue ArgumentError
        raise 'Birthdate column includes invalid data'
      end
    else
      nil
    end
  end

end