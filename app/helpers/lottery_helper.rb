# frozen_string_literal: true

module LotteryHelper
  def link_to_division_delete(division)
    url = organization_lottery_lottery_division_path(division.organization, division.lottery, division)
    tooltip = "Delete this division"
    options = {method: :delete,
               data: {confirm: "This will delete the division, together with all related entrants. Are you sure you want to proceed?",
                      turbo: false,
                      "bs-toggle": :tooltip,
                      placement: :bottom,
                      "bs-original-title": tooltip},
               class: "btn btn-danger btn-sm"}
    link_to fa_icon("trash"), url, options
  end

  def link_to_division_edit(division)
    url = edit_organization_lottery_lottery_division_path(division.organization, division.lottery, division)
    tooltip = "Edit this division"
    options = {data: {"bs-toggle": :tooltip,
                      placement: :bottom,
                      "bs-original-title": tooltip},
               class: "btn btn-primary btn-sm"}
    link_to fa_icon("pencil-alt"), url, options
  end

  def link_to_entrant_delete(entrant)
    url = organization_lottery_lottery_entrant_path(entrant.organization, entrant.lottery, entrant)
    tooltip = "Delete this entrant"
    options = {method: :delete,
               data: {confirm: "This will delete the entrant and cannot be undone. Are you sure you want to proceed?",
                      turbo: false,
                      "bs-toggle": :tooltip,
                      placement: :bottom,
                      "bs-original-title": tooltip},
               class: "btn btn-danger btn-sm"}
    link_to fa_icon("trash"), url, options
  end

  def link_to_entrant_edit(entrant)
    url = edit_organization_lottery_lottery_entrant_path(entrant.organization, entrant.lottery, entrant)
    tooltip = "Edit this entrant"
    options = {data: {"bs-toggle": :tooltip,
                      placement: :bottom,
                      "bs-original-title": tooltip},
               class: "btn btn-primary btn-sm"}
    link_to fa_icon("pencil-alt"), url, options
  end

  def pre_selected_badge_with_label(entrant, tag: :h5)
    content_tag(tag) do
      concat "Pre-selected: "
      concat badgeize_boolean(entrant.pre_selected)
    end
  end
end
