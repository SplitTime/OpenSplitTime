# frozen_string_literal: true

module Searchable
  extend ActiveSupport::Concern
  include PgSearch::Model

  included do
    pg_search_scope :search_names_and_locations,
                    against: [:first_name, :last_name, :city, :state_name, :country_name],
                    using: {
                      tsearch: { prefix: true },
                      dmetaphone: {}
                    }

    scope :names_locations_default_all, -> (param) { param.present? ? search_names_and_locations(param) : all }
    scope :gender_matches, -> (param) { where("#{table_name}.gender = ?", gender_int(param)) }
    scope :country_matches, -> (param) { where(arel_table['country_code'].matches("#{country_code_for(param)}")) }
    scope :state_matches, -> (param) { where(arel_table['state_code'].matches("#{state_code_for(param)}")) }
    scope :email_matches, -> (param) { where(arel_table['email'].matches("%#{param}%")) }
    scope :first_name_matches, -> (param) { where(arel_table['first_name'].matches("%#{param}%")) }
    scope :first_name_matches_exact, -> (param) { where(arel_table['first_name'].matches("#{param}")) }
    scope :last_name_matches, -> (param) { where(arel_table['last_name'].matches("#{param}%")) }
    scope :last_name_matches_exact, -> (param) { where(arel_table['last_name'].matches("#{param}")) }
    scope :full_name_matches, -> (param) { where("regexp_replace((first_name || last_name), '[^a-zA-Z0-9]+', '', 'g') ILIKE ?", "#{normalize(param)}") }
  end

  module ClassMethods
    def state_code_for(param)
      param_state = Carmen::Country.coded("US").subregions.named(param) || Carmen::Country.coded("CA").subregions.named(param)
      param_state ? param_state.code : param
    end

    def country_code_for(param)
      param_country = Carmen::Country.named(param)
      param_country ? param_country.code : param
    end

    def gender_int(param)
      gender_params.find { |_, values| values.include?(param) }&.first
    end

    def normalize(param)
      param.gsub(/[\W_]+/, '')
    end

    private

    def union_sql(param, field_name)
      return nil unless param.present?
      klass = self.name.underscore.pluralize
      terms = param.split
      terms.map { |term| "#{klass}.#{field_name} = '#{term}'" }.join(' OR ')
    end

    def gender_params
      {0 => ['male', 0, :male],
       1 => ['female', 1, :female]}
    end
  end
end
