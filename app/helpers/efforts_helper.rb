# frozen_string_literal: true

module EffortsHelper
  def data_status_class(effort_row)
    if effort_row.bad?
      "text-danger"
    elsif effort_row.questionable?
      "text-warning"
    else
      ""
    end
  end

  def last_reported_location(effort_row)
    if effort_row.started?
      "#{effort_row.final_lap_split_name} (#{pdu('singular')} #{d(effort_row.final_distance)})"
    else
      "--"
    end
  end

  def last_reported_time_of_day(effort_row)
    if effort_row.started?
      day_time_format_hhmmss(effort_row.final_day_and_time).to_s
    else
      "--"
    end
  end

  def last_reported_elapsed_time(effort_row)
    if effort_row.started?
      time_format_hhmmss(effort_row.final_elapsed_seconds).to_s
    else
      "--"
    end
  end

  def lap_time_text(view_object, row)
    true_time = view_object.true_lap_time(row.lap)
    provisional_time = view_object.provisional_lap_time(row.lap)
    provisional_marker = provisional_time && !true_time ? "*" : ""
    time_string = time_format_hhmmss(true_time || provisional_time)
    time_string + provisional_marker
  end

  def link_to_effort_delete(effort)
    url = effort_path(effort)
    tooltip = "Delete effort"
    options = { method: :delete,
                data: { confirm: "This cannot be undone. Continue?",
                        controller: :tooltip,
                        bs_placement: :bottom,
                        bs_original_title: tooltip },
                class: "btn btn-danger" }
    link_to fa_icon("trash"), url, options
  end

  def link_to_effort_edit(effort)
    url = edit_effort_path(effort)
    tooltip = "Edit effort"
    options = { data: { turbo_frame: "form_modal",
                        controller: "tooltip",
                        bs_placement: :bottom,
                        bs_original_title: tooltip },
                class: "btn btn-primary" }
    link_to fa_icon("pencil-alt"), url, options
  end

  def effort_row_confirm_buttons(row)
    if row.absolute_times_local.compact.present?
      row.time_data_statuses.each_with_index do |data_status, i|
        split_time_id = row.split_time_ids[i]
        new_data_status = data_status == "confirmed" ? nil : "confirmed"
        button_class = data_status == "confirmed" ? "success" : "outline-success"
        split_time_data = { split_time: { data_status: new_data_status } }
        url = split_time_id.blank? ? "#" : split_time_path(split_time_id)
        html_options = {
          disabled: split_time_id.blank?,
          class: "btn btn-sm btn-#{button_class} mx-1",
          method: :patch,
          params: split_time_data,
          data: {
            turbo_submits_with: fa_icon("spinner", class: "fa-spin"),
          },
        }

        button = button_to(url, html_options) { fa_icon("thumbs-up") }
        concat button
      end
    end
  end

  def effort_row_delete_buttons(row)
    if row.split_time_ids.compact.present?
      row.split_time_ids.each do |id|
        url = id.blank? ? "#" : split_time_path(id)
        html_options = {
          disabled: id.blank?,
          class: "btn btn-sm btn-outline-danger mx-1",
          method: :delete,
          data: {
            turbo_confirm: "This action cannot be undone. OK to proceed?",
            turbo_submits_with: fa_icon("spinner", class: "fa-spin"),
          },
        }

        button = button_to(url, html_options) { fa_icon("trash") }
        concat button
      end
    end
  end

  def link_to_start_effort(effort)
    link_to "Start effort",
            start_form_effort_path(effort),
            class: "btn btn-success mx-1",
            data: { turbo_frame: "form_modal" }
  end

  def effort_start_time_string(presenter)
    if presenter.calculated_start_time
      content_tag(:h6) do
        concat content_tag(:strong, "Start Time: ")
        concat l(@presenter.calculated_start_time_local, format: :full_day_time_and_zone)
      end
    end
  end

  def effort_view_status(presenter)
    finish_status = presenter.finish_status
    overall_place = presenter.beyond_start ? "#{presenter.overall_rank.ordinalize} Place" : nil
    gender_place = presenter.beyond_start ? "#{presenter.gender_rank.ordinalize} #{presenter.gender.titleize}" : nil
    bib_number = presenter.bib_number ? "Bib ##{presenter.bib_number}" : nil

    content_tag(:h6) do
      concat content_tag(:strong, "Status: ")
      concat [finish_status, overall_place, gender_place, bib_number].compact.join(" • ")
    end
  end
end
