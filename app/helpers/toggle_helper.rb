# frozen_string_literal: true

module ToggleHelper
  def button_to_toggle_check_in(effort)
    if effort.beyond_start?
      button_id = "disabled-effort-#{effort.id}"
      icon_name = "caret-square-right"
      button_text = "Beyond start"
      url = "#"
      params = {}
      disabled = true
      button_class = "primary"
    elsif effort.started?
      button_id = "unstart-effort-#{effort.id}"
      icon_name = "caret-square-right"
      button_text = "Started"
      url = unstart_effort_path(effort)
      params = {}
      disabled = false
      button_class = "primary"
    elsif effort.checked_in?
      button_id = "un-check-in-effort-#{effort.id}"
      icon_name = "check-square"
      button_text = "Checked in"
      url = effort_path(effort)
      params = { effort: { checked_in: false } }
      disabled = false
      button_class = "success"
    else
      button_id = "check-in-effort-#{effort.id}"
      icon_name = "square"
      button_text = "Check in"
      url = effort_path(effort)
      params = { effort: { checked_in: true } }
      disabled = false
      button_class = "outline-secondary"
    end

    html_options = {
      id: button_id,
      class: "btn btn-#{button_class}",
      method: :patch,
      disabled: disabled,
      params: params,
      form_class: "d-grid",
      data: {
        turbo_submits_with: fa_icon("spinner", class: "fa-spin"),
      },
    }

    button_to(url, html_options) { fa_icon(icon_name, text: button_text, type: :regular) }
  end

  def button_to_check_in_all(view_object)
    url = update_all_efforts_event_group_path(view_object.event_group)
    html_options = {
      id: "check_in_all",
      class: "btn btn-success",
      method: "patch",
      params: { efforts: { checked_in: true }, button: :check_in_all },
      data: {
        turbo_confirm: "This will check in all entrants, making them eligible to start. Do you want to proceed?",
        turbo_submits_with: fa_icon("spinner", class: "fa-spin"),
        controller: "tooltip",
        bs_placement: :bottom,
        bs_original_title: "Check in all",
      },
    }
    button_to(url, html_options) { fa_icon("check-square", text: "All", type: :regular) }
  end

  def button_to_check_out_all(view_object)
    url = update_all_efforts_event_group_path(view_object.event_group)
    html_options = {
      id: "check_out_all",
      class: "btn btn-outline-secondary",
      method: "patch",
      params: { efforts: { checked_in: false }, button: :check_out_all },
      data: {
        turbo_confirm: "This will check out all unstarted entrants, making them ineligible to start. Do you want to proceed?",
        turbo_submits_with: fa_icon("spinner", class: "fa-spin"),
        controller: "tooltip",
        bs_placement: :bottom,
        bs_original_title: "Check out all",
      },
    }
    button_to(url, html_options) { fa_icon("square", text: "All", type: :regular) }
  end

  def link_to_subscription(subscribable, protocol)
    protocol = protocol.to_s
    raise ArgumentError, "Improper protocol: #{protocol}" unless protocol.in?(%w[email sms])

    update_type = case subscribable.class.name
                  when "Effort"
                    "live progress"
                  when "Person"
                    "future event sign-up"
                  else
                    raise ArgumentError, "Unknown subscribable class: #{subscribable.class.name}"
                  end

    args = case protocol
           when "email"
             { icon_name: "envelope",
               subscribe_alert: "Receive #{update_type} updates for #{subscribable.full_name}? " +
                 "(You will need to click a link in a confirmation email that will be sent to you " +
                 "from AWS Notifications.)",
               unsubscribe_alert: "Stop receiving #{update_type} updates for #{subscribable.full_name}?" }
           when "sms"
             { icon_name: "mobile-alt",
               subscribe_alert: "Receive #{update_type} updates for #{subscribable.full_name}?",
               unsubscribe_alert: "Stop receiving #{update_type} updates for #{subscribable.full_name}?" }
           else
             {}
           end

    if subscribable.topic_resource_key.present?
      args.merge!(subscribable: subscribable, protocol: protocol)
      if current_user
        link_to_toggle_subscription(args)
      else
        button_to_sign_in(icon: args[:icon_name], protocol: args[:protocol])
      end
    end
  end

  def link_to_toggle_subscription(args)
    subscribable = args[:subscribable]
    icon_name = args[:icon_name]
    protocol = args[:protocol]
    subscribe_alert = args[:subscribe_alert]
    unsubscribe_alert = args[:unsubscribe_alert]
    existing_subscription = subscribable.subscriptions.find_by(user: current_user, protocol: protocol)

    if existing_subscription
      url = polymorphic_path([subscribable, existing_subscription])
      html_options = { method: :delete,
                       class: "#{protocol}-sub btn btn-lg btn-primary click-spinner",
                       data: {
                         turbo_confirm: unsubscribe_alert,
                         turbo_submits_with: fa_icon("spinner", class: "fa-spin", text: protocol),
                       } }
    else
      url = polymorphic_path([subscribable, :subscriptions], subscription: { protocol: protocol })
      html_options = { method: :post,
                       class: "#{protocol}-sub btn btn-lg btn-outline-secondary click-spinner",
                       data: {
                         turbo_confirm: subscribe_alert,
                         turbo_submits_with: fa_icon("spinner", class: "fa-spin", text: protocol),
                       } }
    end

    button_to(url, html_options) { fa_icon(icon_name, text: protocol) }
  end

  def button_to_sign_in(icon:, protocol:)
    url = "#"
    html_options = {
      method: :get,
      class: "btn btn-lg btn-outline-secondary",
      data: {
        turbo_confirm: "You must be signed in to subscribe to notifications.",
      }
    }

    button_to(url, html_options) { fa_icon(icon, text: "#{protocol}") }
  end
end
