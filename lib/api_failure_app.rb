class ApiFailureApp < Devise::FailureApp
  def respond
    content_type = request.content_type || ''
    case
    when content_type.include?('application/vnd.api+json')
      json_api_failure
    when (request.format == :json) || content_type.include?('application/json')
      json_failure
    else
      super
    end
  end

  def json_failure
    self.status = 401
    self.content_type = 'application/json'
    self.response_body = {error: 'Request not authorized.'}.to_json
  end

  def json_api_failure
    self.status = 401
    self.content_type = 'application/vnd.api+json'
    self.response_body = {errors: [{id: :unauthorized,
                                    status: 401,
                                    title: 'Request not authorized.'}]}.to_json
  end
end