# frozen_string_literal: true

class EventConcealedSetter

  attr_reader :response, :status

  def initialize(args)
    @event_group = args[:event_group]
    @concealed = args[:concealed]
    @response = {errors: {}}
  end

  def perform
    set_resources_concealed(concealed)
  end

  private

  attr_reader :event_group, :concealed
  attr_writer :response, :status

  def set_resources_concealed(boolean)
    ActiveRecord::Base.transaction do
      set_resource_concealed(event_group, boolean)
      organization = event_group.organization
      set_resource_concealed(organization, organization.should_be_concealed?) if organization
      event_group.events.eager_load(efforts: :person) do |event|
        event.efforts.each do |effort|
          person = effort.person
          set_resource_concealed(person, person.should_be_concealed?) if person
        end
      end
      raise ActiveRecord::Rollback if status
    end
    self.status ||= :ok
  end

  def set_resource_concealed(resource, boolean)
    class_name = symbolized_class_name(resource)
    resource.concealed = boolean
    if resource.changed?
      unless resource.save
        self.response[:errors][class_name] = resource.errors.full_messages
        self.status = :bad_request
      end
    end
  end

  def symbolized_class_name(resource)
    symbolized_name(resource.class)
  end

  def symbolized_name(klass)
    klass.name.underscore.to_sym
  end
end
