# frozen_string_literal: true

class DuplicateEventGroupParameters < BaseParameters

  def self.permitted
    [:existing_id, :new_name, :new_start_date]
  end
end
