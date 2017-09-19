module Interactors
  Response = Struct.new(:errors, :message) do
    def successful?
      errors.blank?
    end
  end
end
