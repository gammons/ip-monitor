#!/usr/bin/env ruby

require 'net/http'

require 'aws-sdk'
require 'byebug'

DOMAINS_TO_UPDATE = [
  'minecraft.grant.dev.',
  'birdcam.grant.dev.',
  'birdcam-cam.grant.dev.',
  'local.grant.dev.'
]

ZONES = [
  '/hostedzone/ZM1VC2AORLNST' # grant.dev
]

my_ip = Net::HTTP.get(URI('https://api.ipify.org'))
client = Aws::Route53::Client.new(region: 'us-east-2')

ZONES.each do |zone|
  puts "Processing zone #{zone}"

  records = client.list_resource_record_sets(hosted_zone_id: zone).resource_record_sets.select do |r|
    DOMAINS_TO_UPDATE.include?(r.name) && r.type == 'A'
  end

  records.each do |record|
    record_ip = record.resource_records[0].value
    next if record_ip == my_ip

    puts "#{record.name} has ip (#{record_ip}) that is different than my ip #{my_ip}"

    client.change_resource_record_sets(
      {
        change_batch: {
          changes: [
            action: 'UPSERT',
            resource_record_set: {
              name: record.name,
              resource_records: [
                value: my_ip
              ],
              ttl: 60,
              type: 'A'
            }
          ]
        },
        hosted_zone_id: zone
      }
    )
  end
end
