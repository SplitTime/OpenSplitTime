# frozen_string_literal: true

module EffortsHelper
  def data_status_class(effort_row)
    if effort_row.bad?
      'text-danger'
    elsif effort_row.questionable?
      'text-warning'
    else
      ''
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

  def effort_row_confirm_buttons(row, effort)
    if row.absolute_times_local.compact.present?
      row.time_data_statuses.each_with_index do |data_status, i|
        new_data_status = data_status == 'confirmed' ? '' : 'confirmed'
        button_class = data_status == 'confirmed' ? 'success' : 'outline-secondary'
        effort_data = {split_times_attributes: {id: row.split_time_ids[i], data_status: new_data_status}}
        url = update_split_times_effort_path(effort, effort: effort_data)
        options = {method: :patch,
                   disabled: row.split_time_ids[i].blank?,
                   class: "btn btn-#{button_class}"}
        concat link_to fa_icon('thumbs-up'), url, options
        concat ' '
      end
    end
  end

  def effort_row_delete_buttons(row, effort)
    if row.split_time_ids.compact.present?
      row.split_time_ids.each do |id|
        url = delete_split_times_effort_path(effort, split_time_ids: [id])
        options = {method: :delete,
                   disabled: id.blank?,
                   data: {confirm: 'This action cannot be undone. OK to proceed?'},
                   class: 'btn btn-danger'}
        concat link_to fa_icon('trash'), url, options
        concat ' '
      end
    end
  end

  def link_to_start_effort(view_object)
    time = view_object.assumed_start_time_local
    button_tag 'Start effort', class: "btn btn-success", data: {action: 'click->roster#showModal',
                                                                title: "Start Effort",
                                                                time: time.to_s,
                                                                displaytime: l(time, format: :datetime_input)}
  end

  def effort_view_status(presenter)
    finish_status = presenter.finish_status
    overall_place = presenter.overall_rank ? "#{presenter.overall_rank.ordinalize} Place" : ''
    gender_place = presenter.gender_rank ? "#{presenter.gender_rank.ordinalize} #{presenter.gender.titleize}" : ''
    bib_number = presenter.bib_number ? "Bib ##{presenter.bib_number}" : ''

    content_tag(:h6) do
      concat content_tag(:strong, 'Status: ')
      concat [finish_status, overall_place, gender_place, bib_number].compact.join(' • ')
    end
  end
end
