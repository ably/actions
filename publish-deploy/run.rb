#!/usr/bin/env ruby

require "aws-sdk-dynamodb"
require "json"

class Deployments
  attr_reader :table_name, :manifest_id, :services, :release_tag, :dynamodb

  def initialize
    # Add action inputs as environment variables. Unfortunately hyphens
    # do not get converted to underscores.
    @table_name = ENV.fetch("INPUT_TABLE-NAME")

    @manifest_id = ENV.fetch("INPUT_MANIFEST-ID")
    @release_tag = ENV.fetch("INPUT_RELEASE-TAG")
    @services = ENV.fetch("INPUT_SERVICES", "").split(",")

    # Create dynamodb client
    @dynamodb = Aws::DynamoDB::Client.new
  end

  def run!
    puts "Starting publish-deploy #{Time.now.utc}"
    if services.empty?
      puts "No services provided, nothing to do!"
      return
    end

    publish
  end

  def publish
    retries ||= 0

    itrn = next_iteration
    version = create_manifest_version(itrn)
    tags = generate_service_image_tags

    object = {
      "id" => manifest_id,
      "date" => date,
      "version" => version,
      "iteration" => itrn,
      "timestamp" => Time.now.utc.to_s,
      "service_image_tags" => tags
    }

    dynamodb.put_item(
      table_name: table_name,
      item: object,
      condition_expression: "attribute_not_exists(version)"
    )

    set_output("manifest-version", version)
    append_step_summary("**#{version}**")

    puts "Deploy manifest published:"
    puts JSON.pretty_generate(object)
  rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException
    if (retries += 1) < 10
      sleep 1
      retry
    else
      raise
    end
  end

  private

  def date
    Date.today.strftime("%Y%m%d")
  end

  def next_iteration
    dynamodb.query(
      table_name: table_name,
      select: "COUNT",
      key_conditions: {date: {attribute_value_list: [date], comparison_operator: "EQ"}}
    ).count
  end

  def previous_version
    dynamodb.query(
      table_name: table_name,
      index_name: "id-index",
      key_condition_expression: "id = :id",
      expression_attribute_values: {":id" => manifest_id}
    ).items.max_by { |i| [i["date"], i["iteration"]] }
  end

  def generate_service_image_tags
    prev = previous_version

    tags = {}
    services.each do |service|
      tags[service] = release_tag
    end

    return tags unless prev&.dig("service_image_tags")

    prev["service_image_tags"].merge(tags)
  end

  def create_manifest_version(itrn)
    "deploy-#{date}.#{itrn}-#{manifest_id}"
  end

  def set_output(name, value)
    puts "::set-output name=#{name}::#{value}"
  end

  def append_step_summary(message)
    File.write(ENV["GITHUB_STEP_SUMMARY"], message, mode: "a+")
  end
end

Deployments.new.run!
