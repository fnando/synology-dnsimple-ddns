# frozen_string_literal: true

require "net/http"
require "json"

module Net
  def HTTP.patch(url, data, header = nil)
    start(url.hostname, url.port, use_ssl: url.scheme == "https") do |http|
      http.patch(url, data, header)
    end
  end
end

class DNSimpleDDNS
  attr_reader :dnsimple_api_key, :records, :ip

  def initialize(dnsimple_api_key:, records:, ip:)
    @dnsimple_api_key = dnsimple_api_key
    @records = records
    @ip = ip
  end

  def cache
    @cache ||= {}
  end

  def run
    set_dnsimple_account_id

    unless cache[:dnsimple_account_id]
      raise "no dnsimple account id, waiting 30s before retrying."
    end

    update_dns
  end

  def update_dns
    log("ip address is #{ip.inspect}")

    records.each {|record| set_dns(record, ip) }
  end

  def set_dns(record, ip_address)
    entries = dnsimple_get(
      "#{cache[:dnsimple_account_id]}/zones/#{record[:domain]}/records?type=A"
    ).fetch(:data)

    entry = entries.find {|e| e[:name] == record[:name].to_s }

    if entry
      if entry[:content] == ip_address
        log("dns record is already pointing to #{ip_address}")
      else
        update_dns_record(entry, ip_address)
      end
    else
      create_dns_record(record, ip_address)
    end
  end

  def create_dns_record(record, ip_address)
    log("creating dns record for #{record[:name]}.#{record[:domain]}")

    response = dnsimple_post(
      "#{cache[:dnsimple_account_id]}/zones/#{record[:domain]}/records",
      name: record[:name] || "",
      type: "A",
      content: ip_address,
      ttl: record[:ttl] || 60
    )

    log("result when creating dns record: #{response.code}")
  end

  def update_dns_record(entry, ip_address)
    log("updating dns record for #{entry[:name]}.#{entry[:zone_id]}")

    response = dnsimple_patch(
      "#{cache[:dnsimple_account_id]}/zones/#{entry[:zone_id]}/records/#{entry[:id]}",
      content: ip_address
    )

    log("result when updating dns record: #{response.code}")
  end

  def set_dnsimple_account_id
    return if cache[:dnsimple_account_id]

    p dnsimple_get("accounts")
    account_id = dnsimple_get("accounts").dig(:data, 0, :id)
    cache[:dnsimple_account_id] = account_id

    update_cache(dnsimple_account_id: account_id)
  end

  def log(*messages)
    puts "[#{Time.now}] #{messages.join(' ')}"
  end

  def update_cache(**values)
    @cache = cache.merge(values)
  end

  def dnsimple_get(path)
    url = File.join("https://api.dnsimple.com/v2", path)

    log("GET #{url}")

    JSON.parse(
      Net::HTTP.get(
        URI(url),
        "Authorization" => "Bearer #{dnsimple_api_key}"
      ),
      symbolize_names: true
    )
  end

  def dnsimple_post(path, data)
    url = File.join("https://api.dnsimple.com/v2", path)

    log("POST #{url}")

    Net::HTTP.post(
      URI(url),
      JSON.dump(data),
      "Authorization" => "Bearer #{dnsimple_api_key}",
      "Content-Type" => "application/json"
    )
  end

  def dnsimple_patch(path, data)
    url = File.join("https://api.dnsimple.com/v2", path)

    log("PATCH #{url}")

    Net::HTTP.patch(
      URI(url),
      JSON.dump(data),
      "Authorization" => "Bearer #{dnsimple_api_key}",
      "Content-Type" => "application/json"
    )
  end
end
