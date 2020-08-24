# frozen_string_literal: true

module Api
  module V1
    class RawTimeSerializer < ::Api::V1::BaseSerializer
      set_type :raw_times

      attributes :id, :source, :absolute_time, :entered_time, :bib_number, :lap, :split_name, :sub_split_kind,
                 :data_status, :with_pacer, :remarks
    end
  end
end
