# frozen_string_literal: true

module ETL
  class CsvTemplates
    PERSON_ATTRIBUTES = [
      "First Name",
      "Last Name",
      "Gender",
      "Birthdate",
      "Age",
      "Email",
      "Phone",
      "City",
      "State",
      "Country",
    ]

    EFFORT_ATTRIBUTES = [
      *PERSON_ATTRIBUTES,
      "Bib Number",
    ]

    FIXED_HEADERS_BY_FORMAT = {
      event_course_splits: [
        "Split Name",
        "Distance From Start",
        "Kind",
        "Vert Gain From Start",
        "Vert Loss From Start",
        "Latitude",
        "Longitude",
        "Elevation",
        "Sub Split Kinds",
      ],
      event_entrants_with_elapsed_times: EFFORT_ATTRIBUTES,
      event_entrants_with_military_times: EFFORT_ATTRIBUTES,
      event_group_entrants: EFFORT_ATTRIBUTES,
      lottery_entrants: PERSON_ATTRIBUTES,
    }.freeze

    def self.headers(format, parent)
      new(format, parent).headers
    end

    def initialize(format, parent)
      @format = format.to_sym
      @parent = parent
      @header_array = []
    end

    def headers
      fixed_headers = FIXED_HEADERS_BY_FORMAT.fetch(format)

      fixed_headers + variable_headers
    end

    private

    attr_reader :format, :parent, :header_array

    def variable_headers
      case format
      when :event_entrants_with_elapsed_times
        split_names_for_event(parent)
      when :event_entrants_with_military_times
        split_names_for_event(parent)
      when :event_group_entrants
        parent.multiple_events? ? ["Event Name"] : []
      else
        []
      end
    end

    def split_names_for_event(event)
      event.required_time_points.map do |time_point|
        split = event.splits.find { |split| split.id == time_point.split_id }
        split.name(time_point.bitkey)
      end
    end
  end
end
