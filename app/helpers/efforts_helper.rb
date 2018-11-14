# frozen_string_literal: true

module EffortsHelper

  def data_status_tag(effort_row)
    if effort_row.bad?
      tag('tr', class: "text-danger")
    elsif effort_row.questionable?
      tag('tr', class: "text-warning")
    else
      tag('tr')
    end
  end

  def last_reported_location(effort_row)
    if effort_row.started?
      "#{effort_row.final_lap_split_name} (#{pdu('singular')} #{d(effort_row.final_distance)})"
    else
      '--'
    end
  end

  def last_reported_time_of_day(effort_row)
    if effort_row.started?
      "#{day_time_format_hhmmss(effort_row.final_day_and_time)}"
    else
      '--'
    end
  end

  def last_reported_elapsed_time(effort_row)
    if effort_row.started?
      "#{time_format_hhmmss(effort_row.final_time_from_start)}"
    else
      '--'
    end
  end

  def lap_time_text(view_object, row)
    true_time = view_object.true_lap_time(row.lap)
    provisional_time = view_object.provisional_lap_time(row.lap)
    provisional_marker = (provisional_time && !true_time) ? '*' : ''
    time_string = time_format_hhmmss(true_time || provisional_time)
    time_string + provisional_marker
  end
end
