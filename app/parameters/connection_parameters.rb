class ConnectionParameters < BaseParameters
  def self.permitted
    [
      :service_identifier,
      :source_id,
    ]
  end
end
