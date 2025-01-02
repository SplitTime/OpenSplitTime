# Used for models with a 'concealed' attribute.

# Not used on the Event or Effort models, which need custom logic based on the
# concealed status of parent or grandparent records.

module Concealable
  extend ActiveSupport::Concern

  included do
    scope :visible, -> { where("#{table_name}.concealed is not true") }
    scope :concealed, -> { where("#{table_name}.concealed is true") }
  end

  def visible?
    !concealed?
  end

  alias visible visible?
end
