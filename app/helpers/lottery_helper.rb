# frozen_string_literal: true

module LotteryHelper
  def link_to_division_delete(division)
    url = organization_lottery_lottery_division_path(division.organization, division.lottery, division)
    tooltip = "Delete this division"
    options = { data: { turbo_confirm: "This will delete the division, together with all related entrants. Are you sure you want to proceed?",
                        turbo_method: :delete,
                        controller: :tooltip,
                        bs_placement: :bottom,
                        bs_original_title: tooltip },
                class: "btn btn-outline-danger btn-sm" }
    link_to fa_icon("trash"), url, options
  end

  def link_to_division_edit(division)
    url = edit_organization_lottery_lottery_division_path(division.organization, division.lottery, division)
    tooltip = "Edit this division"
    options = { data: { controller: :tooltip,
                        bs_placement: :bottom,
                        bs_original_title: tooltip },
                class: "btn btn-outline-primary btn-sm" }
    link_to fa_icon("pencil-alt"), url, options
  end

  def link_to_entrant_delete(entrant)
    url = organization_lottery_lottery_entrant_path(entrant.organization, entrant.lottery, entrant)
    tooltip = "Delete this entrant"
    options = { turbo_visit_control: "reload",
                data: { turbo_confirm: "This will delete the entrant and cannot be undone. Are you sure you want to proceed?",
                        turbo_method: :delete,
                        turbo_frame: "_top",
                        controller: :tooltip,
                        bs_placement: :bottom,
                        bs_original_title: tooltip },
                class: "btn btn-outline-danger btn-sm" }
    link_to fa_icon("trash"), url, options
  end

  def link_to_entrant_edit(entrant)
    url = edit_organization_lottery_lottery_entrant_path(entrant.organization, entrant.lottery, entrant)
    tooltip = "Edit this entrant"
    options = { data: { controller: :tooltip,
                        bs_placement: :bottom,
                        bs_original_title: tooltip },
                class: "btn btn-outline-primary btn-sm" }
    link_to fa_icon("pencil-alt"), url, options
  end

  def pre_selected_badge_with_label(entrant, tag: :h5)
    content_tag(tag) do
      concat "Pre-selected: "
      concat badgeize_boolean(entrant.pre_selected)
    end
  end
end
