class EventConcealedSetter

  attr_reader :response, :status

  def initialize(args)
    @event = args[:event]
    @response = {errors: {}}
  end

  def make_public
    set_resources_concealed(false)
  end

  def make_private
    set_resources_concealed(true)
  end

  private

  attr_reader :event
  attr_writer :response, :status

  def set_resources_concealed(boolean)
    ActiveRecord::Base.transaction do
      set_resource_concealed(event, boolean)
      organization = event.organization
      set_resource_concealed(organization, organization.should_be_concealed?) if organization
      event.efforts.includes(person: {efforts: :event}).each do |effort|
        person = effort.person
        set_resource_concealed(person, person.should_be_concealed?) if person
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