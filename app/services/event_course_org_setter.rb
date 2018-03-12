# frozen_string_literal: true

class EventCourseOrgSetter

  attr_reader :resources, :status

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:event, :params],
                           exclusive: [:event, :event_group, :course, :organization, :params],
                           class: self.class)
    @event = args[:event]
    @event_group = args[:event_group]
    @course = args[:course]
    @organization = args[:organization]
    @params = args[:params]
    @resources = []
  end

  def set_resources
    ActiveRecord::Base.transaction do
      add_event_group_name
      submitted_resources.each do |resource|
        update_resource(resource)
      end
      raise ActiveRecord::Rollback if status
    end
    self.status ||= :ok
  end

  private

  attr_reader :event, :event_group, :course, :organization, :params
  attr_writer :response, :status

  def add_event_group_name
    event_group.name ||= params[:event][:name]
  end

  def submitted_resources
    [course, organization, event_group, event]
  end

  def update_resource(resource)
    if resource.update(class_params(resource.class))
      resource.reload
    else
      self.status = :unprocessable_entity
    end
    self.resources << resource
  end

  def relationships
    result = {event: {event_group: event_group, course: course}, event_group: {organization: organization}}
    result.default = {}
    result
  end

  def class_params(klass)
    (params[symbolized_name(klass)] || ActionController::Parameters.new)
        .permit(*"#{klass}Parameters".constantize.permitted)
        .merge(relationships[symbolized_name(klass)])
  end

  def symbolized_class_name(resource)
    symbolized_name(resource.class)
  end

  def symbolized_name(klass)
    klass.name.underscore.to_sym
  end
end
