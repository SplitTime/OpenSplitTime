module Searchable
  extend ActiveSupport::Concern

  include SetOperations

  included do
    scope :gender_matches, -> (param) { where("gender = ?", gender_int(param)) }
    scope :country_matches, -> (param) { where(arel_table['country_code'].matches("#{country_code_for(param)}")) }
    scope :state_matches, -> (param) { where(arel_table['state_code'].matches("#{state_code_for(param)}")) }
    scope :first_name_matches, -> (param) { where(arel_table['first_name'].matches("%#{param}%")) }
    scope :first_name_matches_exact, -> (param) { where(arel_table['first_name'].matches("#{param}")) }
    scope :last_name_matches, -> (param) { where(arel_table['last_name'].matches("#{param}%")) }
    scope :last_name_matches_exact, -> (param) { where(arel_table['last_name'].matches("#{param}")) }
    scope :full_name_matches, -> (param) { where("regexp_replace((first_name || last_name), '[^a-zA-Z0-9]+', '', 'g') ILIKE ?", "#{normalize(param)}") }
    scope :search_term_scope, -> (term) { union_scope(country_matches(term), state_matches(term), first_name_matches(term), last_name_matches(term)) }
  end

  module ClassMethods

    def flexible_search(param)
      collection = all
      terms = tokenize(param)
      terms.each do |term|
        collection = collection.search_term_scope(term)
      end
      collection
    end

    private

    def gender_int(param)
      return 0 if (param == "male") || (param == 0) || (param == :male)
      return 1 if (param == "female") || (param == 1) || (param == :female)
    end

    def country_code_for(param)
      param_country = Carmen::Country.named(param)
      param_country ? param_country.code : nil
    end

    def state_code_for(param)
      param_state = Carmen::Country.coded("US").subregions.named(param) || Carmen::Country.coded("CA").subregions.named(param)
      param_state ? param_state.code : nil
    end

    def normalize(param)
      param.gsub(/[\W_]+/, '')
    end

    def tokenize(str)
      str.split(/\s(?=(?:[^'"]|'[^']*'|"[^"]*")*$)/)
          .select { |s| not s.empty? }
          .map { |s| s.gsub(/(^ +)|( +$)|(^["']+)|(["']+$)/, '') }
    end

  end
end
