# Be sure to restart your server when you modify this file.

# This file contains settings for ActionController::ParamsWrapper which
# is enabled by default.

# Convert json parameters, sent from Javascript UI, from camelCase to snake_case.
# This bridges the gap between javascript and ruby naming conventions.

# Credit to patatepartie http://stackoverflow.com/a/27996031/5961578

module ActionController
  module ParamsNormalizer
    extend ActiveSupport::Concern

    def process_action(*args)
      deep_underscore_params!(request.parameters)
      super
    end

    private
    def deep_underscore_params!(val)
      case val
      when Array
        val.map {|v| deep_underscore_params! v }
      when Hash
        val.keys.each do |k, v = val[k]|
          val.delete k
          val[k.underscore] = deep_underscore_params!(v)
        end
        val
      else
        val
      end
    end
  end
end

# Enable parameter wrapping for JSON. You can disable this by setting :format to an empty array.
ActiveSupport.on_load(:action_controller) do
  wrap_parameters format: [:json] if respond_to?(:wrap_parameters)
  # Include the above defined concern
  include ::ActionController::ParamsNormalizer
end

# To enable root element in JSON for ActiveRecord objects.
# ActiveSupport.on_load(:active_record) do
#   self.include_root_in_json = true
# end
