module Connectors::Errors
  class Base < RuntimeError; end
  class MissingCredentials < Base; end
  class NotAuthenticated < Base; end
  class NotAuthorized < Base; end
  class NotFound < Base; end
  class BadRequest < Base; end
  class BadConnection < Base; end
end
