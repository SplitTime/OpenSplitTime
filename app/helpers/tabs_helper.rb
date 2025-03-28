module TabsHelper
  def effort_view_tabs(view_object)
    if !view_object.simple? || current_user&.authorized_to_edit?(view_object.effort)
      items = [{ name: "Split times",
                 link: effort_path(view_object.effort),
                 active: action_name == "show" },
               { name: "Projections",
                 link: projections_effort_path(view_object.effort),
                 active: action_name == "projections",
                 hidden: view_object.simple? || !view_object.in_progress? },
               { name: "Analyze times",
                 link: analyze_effort_path(view_object.effort),
                 active: action_name == "analyze",
                 hidden: view_object.simple? || view_object.not_analyzable? },
               { name: "Places + peers",
                 link: place_effort_path(view_object.effort),
                 active: action_name == "place",
                 hidden: view_object.simple? || view_object.not_analyzable? },
               { name: "Audit",
                 link: audit_effort_path(view_object.effort),
                 active: action_name == "audit",
                 hidden: !current_user&.authorized_to_edit?(view_object.effort) }]

      build_view_tabs(items)
    end
  end

  def course_view_tabs(view_object)
    items = [
      { name: "Splits",
        link: organization_course_path(view_object.organization, view_object.course, display_style: "splits"),
        active: action_name == "show" && view_object.display_style == "splits" },
      { name: "Events",
        link: organization_course_path(view_object.organization, view_object.course, display_style: "events"),
        active: action_name == "show" && view_object.display_style == "events" },
      { name: "All-time best",
        link: organization_course_best_efforts_path(view_object.organization, view_object.course),
        active: controller_name == "course_best_efforts" },
      { name: "Plan my effort",
        link: plan_effort_organization_course_path(view_object.organization, view_object.course),
        active: action_name == "plan_effort",
        hidden: view_object.simple? },
      { name: "Cutoff analysis",
        link: cutoff_analysis_organization_course_path(view_object.organization, view_object.course),
        active: action_name == "cutoff_analysis",
        hidden: view_object.simple? },
    ]

    build_view_tabs(items)
  end

  private

  def build_view_tabs(items)
    content_tag(:ul, class: "nav nav-tabs nav-tabs-ost") do
      items.each do |item|
        next if item[:hidden]

        active_class = item[:active] ? "active" : nil

        list_item = content_tag(:li, class: ["nav-item", active_class].compact.join(" ")) do
          item[:active] ? content_tag(:a, item[:name]) : link_to(item[:name], item[:link])
        end

        concat(list_item)
      end
    end
  end
end
