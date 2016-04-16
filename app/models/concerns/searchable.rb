module Searchable
  extend ActiveSupport::Concern

  module ClassMethods

    def first_name_matches(param, rigor = 'soft')
      return matches('first_name', param) || none if rigor == 'soft'
      exact_matches('first_name', param) || none
    end

    def last_name_matches(param, rigor = 'soft')
      return matches('last_name', param) || none if rigor == 'soft'
      exact_matches('last_name', param) || none
    end

    def full_name_matches(param, resources, rigor = 'soft')
      matches = []
      if rigor == 'soft'
        resources.each do |resource|
          if "%#{resource.full_name.strip.downcase}%" == "%#{param.strip.downcase}%"
            matches << resource
          end
        end
      else
        resources.each do |resource|
          if resource.full_name.strip.downcase == param.strip.downcase
            matches << resource
          end
        end
      end
      matches
    end

    def gender_matches(param)
      gender_int = 1 if param == "female"
      gender_int = 1 if param == 1
      gender_int = 0 if param == "male"
      gender_int = 0 if param == 0
      where(gender: gender_int)
    end

    def country_matches(param)
      param_country = Carmen::Country.named(param)
      if param_country
        param_country_code = param_country.code
        where(country_code: param_country_code) || none
      else
        none
      end
    end

    def state_matches(param)
      uncoded_matches = exact_matches('state_code', param)
      param_state = Carmen::Country.coded("US").subregions.named(param) || Carmen::Country.coded("CA").subregions.named(param)
      if param_state
        param_state_code = param_state.code
        coded_matches = where(state_code: param_state_code)
      else
        coded_matches = none
      end
      (uncoded_matches + coded_matches).uniq || none
    end

    def email_matches(param, rigor = 'exact')
      return matches('email', param) || none if rigor == 'soft'
      exact_matches('email', param) || none
    end

    def matches(field_name, param)
      where(arel_table[field_name].matches("%#{param}%"))
    end

    def exact_matches(field_name, param)
      where(arel_table[field_name].matches("#{param}"))
    end

    def search(param)
      return all if param.blank?
      param.downcase!
      collection = country_matches(param) + state_matches(param)
      terms = param.split(" ")
      terms.each do |term|
        collection = collection + first_name_matches(term, 'soft') +
            last_name_matches(term, 'soft') +
            country_matches(term) +
            state_matches(term)
      end
      collection.uniq
    end

  end
end
