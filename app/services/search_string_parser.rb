# frozen_string_literal: true

class SearchStringParser
  def initialize(search_string)
    @search_string = search_string&.downcase
  end

  def number_component
    return "" unless search_string.present?

    clean_number_string
  end

  def word_component
    return "" unless search_string.present?

    clean_word_string
  end

  private

  attr_reader :search_string

  def clean_words
    @clean_words ||= search_string.gsub(/[^[a-zA-Z ]]/, '').split
  end

  def clean_word_string
    @clean_word_string ||= clean_words.join(' ')
  end

  def clean_number_string
    @clean_number_string ||= search_string.gsub(/[^[0-9 ]]/, '').split.join(' ')
  end
end
