class ApiFailureApp < Devise::FailureApp
  def respond
    puts "ApiFailureApp was called"
    if (request.format == :json) || (request.content_type.include?('application/json'))
      json_failure
    else
      super
    end
  end

  def json_failure
    self.status = 401
    self.content_type = 'application/json'
    self.response_body = "{'error' : 'authentication error'}"
  end
end