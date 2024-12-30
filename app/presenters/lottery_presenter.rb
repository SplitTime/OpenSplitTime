# frozen_string_literal: true

class LotteryPresenter < BasePresenter
  DEFAULT_SORT_HASH = { division_name: :asc, last_name: :asc }.freeze

  attr_reader :lottery, :params
  delegate :action_name, :controller_name, to: :view_context

  delegate :calculation_class?, :concealed?, :divisions, :draws, :entrants, :name, :organization, :scheduled_start_date, :status,
           :tickets, :to_param, :service_form, to: :lottery
  delegate :draws, :entrants, :tickets, to: :lottery, prefix: true

  def initialize(lottery, view_context)
    @lottery = lottery
    @view_context = view_context
    @params = view_context.prepared_params
  end

  # @return [ActiveRecord::Relation<LotteryDivision>]
  def ordered_divisions
    @ordered_divisions ||= divisions.ordered_by_name
  end

  # @return [ActiveRecord::Relation<LotteryDraw>]
  def lottery_draws_ordered
    lottery_draws
      .with_sortable_entrant_attributes
      .include_entrant_and_division
      .most_recent_first
  end

  # @return [ActiveRecord::Relation<LotteryEntrant>]
  def lottery_entrants_default_none
    unfiltered_entrants = lottery.entrants
                                 .with_division_name
                                 .includes(:division, :division_ranking)
    entrant_id = params[:entrant_id]

    if entrant_id.present?
      unfiltered_entrants.where(id: entrant_id)
    else
      unfiltered_entrants.search_default_none(search_text)
    end
  end

  # @return [ActiveRecord::Relation<LotteryEntrant>]
  def lottery_entrants_paginated
    @lottery_entrants_paginated ||= lottery_entrants_filtered.paginate(page: page, per_page: per_page)
  end

  def pre_selected_entrant_count
    @pre_selected_entrant_count ||= lottery_entrants.pre_selected.count
  end

  def first_service_detail_for_review
    return @first_service_detail_for_review if defined?(@first_service_detail_for_review)

    @first_service_detail_for_review = lottery_entrants.pending_completed_form_review.order(:id).first
  end

  # @return [String, nil]
  def next_page_url
    view_context.url_for(request.params.merge(page: page + 1)) if records_from_context_count == per_page
  end

  # @return [ActiveRecord::Relation<Partner>]
  def partners
    @partners ||= lottery.partners.order(:name)
  end

  # @return [ActiveRecord::Relation<LotteryEntrant>, ActiveRecord::Relation<LotteryDraw>]
  def records_from_context
    case display_style
    when "entrants"
      lottery_entrants_paginated
    when "draws"
      lottery_draws
    else
      lottery_draws.none
    end
  end

  # @return [Integer]
  def records_from_context_count
    @records_from_context_count ||= records_from_context.size
  end

  # @return [Hash{String->Array<LotteryDivisionTicketStat>}]
  def stats
    @stats ||= ::LotteryDivisionTicketStat.where(lottery: lottery).order(:division_name, :number_of_tickets).group_by(&:division_name)
  end

  def stats_chart_data(division_stats)
    [
      {
        name: "Accepted",
        data: division_stats.map { |stat| [stat.number_of_tickets, stat.accepted_entrants_count] },
      },
      {
        name: "Waitlisted",
        data: division_stats.map { |stat| [stat.number_of_tickets, stat.waitlisted_entrants_count] },
      },
      {
        name: "Not Drawn",
        data: division_stats.map { |stat| [stat.number_of_tickets, stat.undrawn_entrants_count] },
      },
    ]
  end

  # @return [Boolean]
  def viewable_results?
    lottery.live? || lottery.finished? || current_user&.authorized_for_lotteries?(lottery)
  end

  # @return [String (frozen)]
  def display_style
    params[:display_style].presence || default_display_style
  end

  # @return [String (frozen)]
  def default_display_style
    case status
    when "preview" then "entrants"
    when "live" then "draws"
    when "finished" then "results"
    else "entrants"
    end
  end

  # @return [Partner, nil]
  def partner_with_banner
    @partner_with_banner ||= lottery.pick_partner_with_banner
  end

  # @return [Boolean]
  def show_partner_banners?
    lottery.live? && partner_with_banner.present?
  end

  # @return [Boolean]
  def tickets_not_generated?
    @tickets_not_generated ||= lottery_tickets.empty?
  end

  private

  attr_reader :view_context
  delegate :current_user, :request, to: :view_context, private: true

  # @return [ActiveRecord::Relation<LotteryEntrant>]
  def lottery_entrants_filtered
    lottery_entrants
      .includes([:division_ranking, :service_detail, division: { lottery: :organization }])
      .search(search_text)
      .order(:last_name)
  end
end
