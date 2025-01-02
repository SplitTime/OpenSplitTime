# Set ArgsValidator.console_notifications = true to provide detailed class and parameter
# information when objects are instantiated from classes that call ArgsValidator

ActiveSupport.on_load(:action_controller_base) do
  ArgsValidator.console_notifications = false
end
