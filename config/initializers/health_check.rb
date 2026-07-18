# Bots probe paths like /up.php. The ".php" makes the stock health-check route
# (get "up" => "rails/health#show") negotiate an unknown format and raise ActionController::UnknownFormat,
# which would 500. ApplicationController already turns that into a 406, but the framework health
# controller doesn't inherit it — so extend it here to respond 406 as well.
Rails.application.config.to_prepare do
  Rails::HealthController.rescue_from(ActionController::UnknownFormat) { head :not_acceptable }
end
