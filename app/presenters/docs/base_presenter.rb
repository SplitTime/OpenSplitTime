# frozen_string_literal: true

module Docs
  class BasePresenter < ::BasePresenter
    attr_reader :params, :current_user

    def initialize(params, current_user)
      @params = params
      @current_user = current_user
    end

    def category
      raise NotImplementedError, "#{self.class.name} must implement a category method."
    end

    def display_category
      raise NotImplementedError, "#{self.class.name} must implement a display_category method."
    end

    def topic
      (params[:topic] || default_topic).to_sym
    end

    def display_topic
      items.dig(topic, :display_topic)
    end

    def page
      (params[:page] || 1).to_i
    end

    def page_title
      items.dig(topic, :pages)[page - 1]
    end

    def partial
      "#{category}_#{topic}_#{page}"
    end

    def valid_params?
      File.exist?(Rails.root.join("app/views/docs/visitors/_#{partial}.html.erb"))
    end

    private

    def default_topic
      items.keys.first
    end
  end
end
