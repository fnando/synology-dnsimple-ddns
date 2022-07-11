# frozen_string_literal: true

require "bundler/setup"
Bundler.require

require_relative "dnsimple_ddns"

API_KEY = ENV.fetch("API_KEY", "")
DNSIMPLE_API_KEY = ENV.fetch("DNSIMPLE_API_KEY", "")

get "/" do
  "hello"
end

get "/update" do
  halt(401) if API_KEY != params[:api_key]

  labels = params[:host].split(".")
  name = labels.shift
  domain = labels.join(".")

  DNSimpleDDNS.new(
    ip: params[:ip],
    dnsimple_api_key: DNSIMPLE_API_KEY,
    records: [{name:, domain:}]
  ).run

  "OK"
rescue Exception # rubocop:disable Lint/RescueException
  halt(500)
end
