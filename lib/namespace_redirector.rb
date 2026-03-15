# This class handles logic for redirects from the routes.rb file.
# Requests calling this class should follow a pattern that looks like:
# get "/courses(/*path)" => redirect(::NamespaceRedirector.new("courses"))
class NamespaceRedirector
  def initialize(model)
    @model = model
  end

  def call(params, _request)
    # Redirect to root if no specific path is provided
    return "/" if params[:path].blank?

    case model
    when "courses"
      course_id, tail = params[:path].split("/", 2)
      course = ::Course.friendly.find(course_id)
      ["/organizations/#{course.organization.to_param}/courses/#{course.to_param}", tail].compact.join("/")
    else
      raise "Attempted to redirect with namespace to unknown model: #{model}"
    end
  end

  private

  attr_reader :model
end
