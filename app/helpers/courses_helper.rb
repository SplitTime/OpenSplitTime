# frozen_string_literal: true

module CoursesHelper
  def segment_start_dropdown(view_object)
    ordered_split_params = view_object.ordered_splits.map(&:to_param)
    items = view_object.ordered_splits_without_finish.map do |split|
      split_param = split.to_param
      valid_split2_params = ordered_split_params.elements_after(split_param)
      split2_param = valid_split2_params.include?(view_object.split2) ? view_object.split2 : valid_split2_params.first

      {name: split.base_name,
       link: request.params.merge(split1: split.to_param, split2: split2_param),
       active: view_object.split1.to_param == split.to_param,
       visible: true}
    end
    build_dropdown_menu(nil, items, button: true)
  end

  def segment_finish_dropdown(view_object)
    ordered_split_params = view_object.ordered_splits.map(&:to_param)
    items = view_object.ordered_splits_without_start.map do |split|
      split_param = split.to_param
      valid_split1_params = ordered_split_params.elements_before(split_param)
      split1_param = valid_split1_params.include?(view_object.split1) ? view_object.split1 : valid_split1_params.last

      {name: split.base_name,
       link: request.params.merge(split1: split1_param, split2: split.to_param),
       active: view_object.split2.to_param == split.to_param,
       visible: true}
    end
    build_dropdown_menu(nil, items, button: true)
  end

  def plan_export_headers
    time_of_day_headers = @presenter.out_sub_splits? ? ['Time of Day In', 'Time of Day Out'] : ['Time of Day']
    elapsed_time_headers = @presenter.out_sub_splits? ? ['Elapsed Time In', 'Elapsed Time Out'] : ['Elapsed Time']
    in_aid = @presenter.out_sub_splits? ? ['In Aid'] : []
    lap = @presenter.multiple_laps? ? ['Lap Time'] : []
    ['Split', pdu('singular').titlecase] + time_of_day_headers + elapsed_time_headers + ['Segment'] + in_aid + lap
  end

  def lap_split_export_row(row)
    number_of_times = @presenter.out_sub_splits? ? 2 : 1
    times_of_day = Array.new(number_of_times) { |i| row.days_and_times.map { |day_and_time| day_time_full_format(day_and_time) }[i] }
    elapsed_times = Array.new(number_of_times) { |i| row.times_from_start.map { |time_from_start| time_format_hhmm(time_from_start) }[i] }
    segment_time = [time_format_hhmm(row.segment_time)]
    in_aid_time = case
                  when !@presenter.out_sub_splits?
                    []
                  when row.finish?
                    [time_format_hhmm(@presenter.total_time_in_aid)]
                  else
                    [time_format_hhmm(row.time_in_aid)]
                  end
    lap_time = case
               when !@presenter.multiple_laps?
                 []
               when row.finish?
                 [lap_time_text(@presenter, row)]
               else
                 []
               end

    [row.name, d(row.distance_from_start)] + times_of_day + elapsed_times + segment_time + in_aid_time + lap_time
  end
end
