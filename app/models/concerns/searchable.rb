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
      where(country_code: param) || none
    end

    def state_matches(param, rigor = 'exact')
      return matches('state_code', param) || none if rigor == 'soft'
      exact_matches('state_code', param) || none
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
      collection = []
      terms = param.split(" ")
      terms.each do |term|
        collection = collection + first_name_matches(term, 'soft') +
            last_name_matches(term, 'soft') +
            state_matches(term, 'soft')
        collection = collection + email_matches(term, 'soft') if self.column_names.include?('email')
      end
      collection.uniq
    end

  end
end
