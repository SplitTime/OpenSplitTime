module Api
  module V1
    class RawTimeSerializer < ::Api::V1::BaseSerializer
      set_type :raw_times

      attributes :id,
                 :event_group_id,
                 :source,
                 :absolute_time,
                 :entered_time,
                 :bib_number,
                 :lap,
                 :split_name,
                 :sub_split_kind,
                 :data_status,
                 :stopped_here,
                 :with_pacer,
                 :remarks

      link :self, :api_v1_url

      belongs_to :event_group
    end
  end
end
