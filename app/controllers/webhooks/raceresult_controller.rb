module Webhooks
  class RaceresultController < ApplicationController
    skip_before_action :verify_authenticity_token

    def receive
      puts "SUCCESS! Received data: #{params.inspect}"
      render json: { status: "ok" }
    end
  end
end