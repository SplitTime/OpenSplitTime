require "rspec/retry"

RSpec.configure do |config|
  # Surface retries in the output so browser flakiness stays visible rather than silently masked
  # (tracked in issue #2146).
  config.verbose_retry = true
  config.display_try_failure_messages = true

  # Retry browser (:js) specs, and only on transient Chrome/Ferrum startup or crash errors — never on
  # an assertion failure, which is not in the list and so still fails on the first attempt. Retries
  # only run on CI; locally a flake surfaces immediately. A retry spins up a fresh Chrome process,
  # which is exactly what these errors need.
  config.around(:each, :js) do |example|
    example.run_with_retry(
      retry: ENV["CI"] ? 3 : 1,
      exceptions_to_retry: [Ferrum::ProcessTimeoutError, Ferrum::DeadBrowserError],
    )
  end
end
