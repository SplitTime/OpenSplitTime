# frozen_string_literal: true

class RawTimeSerializer < BaseSerializer
  attributes :id, :absolute_time, :entered_time, :bib_number, :lap, :split_name, :sub_split_kind, :data_status, :with_pacer, :remarks
end
