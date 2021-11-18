# frozen_string_literal: true

module LotteryHelper
  def link_to_division_delete(division)
    url = organization_lottery_lottery_division_path(division.organization, division.lottery, division)
    tooltip = "Delete this division"
    options = {method: :delete,
               data: {confirm: "This will delete the division, together with all related entrants. Are you sure you want to proceed?",
                      turbo: false,
                      toggle: :tooltip,
                      placement: :bottom,
                      "original-title" => tooltip},
               class: "btn btn-danger btn-sm has-tooltip"}
    link_to fa_icon("trash"), url, options
  end

  def link_to_division_edit(division)
    url = edit_organization_lottery_lottery_division_path(division.organization, division.lottery, division)
    tooltip = "Edit this division"
    options = {data: {toggle: :tooltip,
                      placement: :bottom,
                      "original-title" => tooltip},
               class: "btn btn-primary btn-sm has-tooltip"}
    link_to fa_icon("pencil-alt"), url, options
  end

  def link_to_entrant_delete(entrant)
    url = organization_lottery_lottery_entrant_path(entrant.organization, entrant.lottery, entrant)
    tooltip = "Delete this entrant"
    options = {method: :delete,
               data: {confirm: "This will delete the entrant and cannot be undone. Are you sure you want to proceed?",
                      turbo: false,
                      toggle: :tooltip,
                      placement: :bottom,
                      "original-title" => tooltip},
               class: "btn btn-danger btn-sm has-tooltip"}
    link_to fa_icon("trash"), url, options
  end

  def link_to_entrant_edit(entrant)
    url = edit_organization_lottery_lottery_entrant_path(entrant.organization, entrant.lottery, entrant)
    tooltip = "Edit this entrant"
    options = {data: {toggle: :tooltip,
                      placement: :bottom,
                      "original-title" => tooltip},
               class: "btn btn-primary btn-sm has-tooltip"}
    link_to fa_icon("pencil-alt"), url, options
  end

  def link_to_toggle_lottery_public_private(presenter)
    if presenter.concealed?
      set_to_value = false
      button_text = "Make public"
      confirm_text = "NOTE: This will make #{presenter.name} visible to the public. Are you sure you want to proceed?"
    else
      set_to_value = true
      button_text = "Make private"
      confirm_text = "NOTE: This will conceal #{presenter.name} from the public. Are you sure you want to proceed?"
    end

    link_to button_text,
            organization_lottery_path(presenter.organization, presenter.lottery, lottery: {concealed: set_to_value}),
            data: {confirm: confirm_text},
            method: :put,
            class: "btn btn-md btn-warning"
  end

  def pre_selected_badge_with_label(entrant, tag: :h5)
    content_tag(tag) do
      concat "Pre-selected: "
      concat badgeize_boolean(entrant.pre_selected)
    end
  end

  def lottery_status_badge(status)
    color = case status
            when "preview"
              :primary
            when "live"
              :danger
            when "finished"
              :success
            else
              :warning
            end

    content_tag(:span, status.titleize, class: "badge badge-#{color} align-top", style: "font-size:0.8rem;")
  end
end
