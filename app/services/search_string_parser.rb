# frozen_string_literal: true

class SearchStringParser

  def initialize(search_string)
    @search_string = search_string.downcase
  end

  def number_component
    clean_number_string
  end

  def word_component
    clean_word_string
  end

  def state_component
    matching_states.map(&:code).join(' ')
  end

  def country_component
    matching_countries.map(&:code).join(' ')
  end

  def remainder_component
    words = clean_word_string.dup
    matching_geo_terms.each { |term| words.gsub!(term, '') }
    words.split.join(' ')
  end

  private

  attr_reader :search_string

  # Matching state and country names and codes must be removed from the search string to produce
  # a remainder_component. The order of removal is important. Names with multiple words need to be
  # removed first or a portion of a name may not match. For example, if the search string is
  # 'new mexico' and matching_geo_terms includes ['mexico' and 'new mexico'], 'new mexico' needs
  # to be removed first or the remainder will contain 'new'. The final `.sort_by` ensures proper order.
  def matching_geo_terms
    (matching_countries + matching_states).flat_map { |region| [region.name.downcase, region.code.downcase] }
        .sort_by { |string| -string.split.size }
  end

  def matching_countries
    @matching_countries ||= geo_search_terms.map { |term| country_for(term) }.compact
  end

  def matching_states
    @matching_states ||= geo_search_terms.map { |term| state_for(term) }.compact
  end

  def geo_search_terms
    search_term_pairs + clean_words
  end

  def search_term_pairs
    clean_words.each_cons(2).map { |pair| pair.join(' ') }
  end

  def clean_words
    @clean_words ||= search_string.gsub(/[^[a-zA-Z ]]/, '').split
  end

  def clean_word_string
    @clean_word_string ||= clean_words.join(' ')
  end

  def clean_number_string
    @clean_number_string ||= search_string.gsub(/[^[0-9 ]]/, '').split.join(' ')
  end

  def country_for(term)
    term.size == 2 ? Carmen::Country.coded(term) : Carmen::Country.named(term)
  end

  def state_for(term)
    term.size == 2 ?
        (united_states.subregions.coded(term) || canada.subregions.coded(term)) :
        (united_states.subregions.named(term) || canada.subregions.named(term))
  end

  def canada
    @canada ||= Carmen::Country.coded("CA")
  end

  def united_states
    @united_states ||= Carmen::Country.coded("US")
  end
end
