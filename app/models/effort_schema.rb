class EffortSchema

  # to_a returns an array of symbols representing attributes
  # of the effort model.

  # Symbols are returned in order of matching header_column_titles
  # with nil placeholders for titles that don't match
  # any importable effort attribute

  NORMALIZE_MAP = {'countrycode' => 'country',
                   'statecode' => 'state',
                   'bibnumber' => 'bib',
                   'bibno' => 'bib',
                   'firstname' => 'first',
                   'lastname' => 'last',
                   'nation' => 'country',
                   'region' => 'state',
                   'province' => 'state',
                   'sex' => 'gender'}

  delegate :size, :count, :index, :[], :zip, to: :to_a

  def initialize(header_column_titles)
    @header_column_titles = header_column_titles
  end

  def to_a
    @to_a ||= normalized_column_titles.map { |column_title| closest_effort_attribute(column_title) }
  end

  private

  attr_reader :header_column_titles

  def normalized_column_titles
    @normalized_column_titles ||= header_column_titles.map { |title| normalize(title) }
  end

  def effort_attributes_map
    @effort_attributes_map ||= effort_attributes.zip(normalized_effort_attributes).to_h
  end

  def normalized_effort_attributes
    @normalized_effort_attributes ||= effort_attributes.map { |attribute| normalize(attribute) }
  end

  def effort_attributes
    @effort_attributes ||= Effort.attributes_for_import
  end

  def closest_effort_attribute(column_title)
    effort_attributes.find { |effort_attribute| column_title == effort_attributes_map[effort_attribute] }
  end

  def normalize(title)
    clean_title = title.to_s.downcase.gsub(/[\W_]+/, '')
    NORMALIZE_MAP.each { |given, normalized| clean_title.gsub!(given, normalized) }
    clean_title
  end

end