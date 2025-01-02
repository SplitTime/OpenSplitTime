public_key = OstConfig.sendgrid_webhook_verification_key
Rails.application.config.middleware.use Rack::SendGridWebhookVerification, public_key, /\A\/webhooks\/sendgrid_events/
