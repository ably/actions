#!/usr/bin/env ruby

require "aws-sdk-dynamodb"
require "json"

class Builds
  attr_reader :table_name, :dynamodb

  def initialize
    # Add action inputs as environment variables. Unfortunately hyphens
    # do not get converted to underscores.
    @table_name = ENV.fetch("INPUT_TABLE-NAME")

    # Create dynamodb client
    @dynamodb = Aws::DynamoDB::Client.new
  end

  def run!
    puts "Starting update-builds #{Time.now.utc}"
    # If the update input is set, perform an update
    if ENV["INPUT_UPDATE"]&.downcase == "true"
      update
    else
      publish
    end
  end

  def publish
    begin
      retries ||= 0

      itrn = next_iteration
      tag = create_release_tag(itrn)

      object = {
        "branch" => git_branch,
        "build_id" => build_id,
        "commit_author" => git_commit_author,
        "commit_sha" => commit_sha,
        "date" => date,
        "image_tag" => tag,
        "iteration" => itrn,
        "job_url" => job_url,
        "repository" => git_repository,
        "timestamp" => Time.now.utc.to_s
      }

      dynamodb.put_item(
        table_name: "builds",
        item: object,
        condition_expression: "attribute_not_exists(image_tag)"
      )

      set_output("release-tag", tag)
      append_step_summary("**#{tag}**")

      puts "Build published:"
      puts JSON.pretty_generate(object)
    rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException
      if (retries += 1) < 10
        sleep 1
        retry
      else
        raise
      end
    end
  end

  def update
    tag = retrieve_release_tag
    services = ENV.fetch("INPUT_SERVICES").split(",")

    dynamodb.update_item(
      key: {"date" => tag[:date], "iteration" => tag[:iteration].to_i},
      table_name: table_name,
      expression_attribute_names: {"#S" => "services"},
      expression_attribute_values: {":s" => services},
      update_expression: "SET #S = :s"
    )

    set_output("release-tag", tag)

    puts "Build updated for services:"
    puts services.join("\n")
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

  def create_release_tag(itrn)
    # Only use the first 9 characters for readability
    sha = commit_sha[0...9].chars.join

    # Builds are prefixed so that ECR lifecycle rules can be applied against
    # specific images. Anything with the `release` prefix will be stored
    # indefinitely, and anything with `dev` will be deleted.
    prefix = git_branch == "main" ? "release" : "dev"

    "#{prefix}-#{date}.#{itrn}-#{sha}"
  end

  def commit_sha
    ENV.fetch("GITHUB_SHA")
  end

  def git_commit_author
    ENV.fetch("GITHUB_ACTOR")
  end

  def git_branch
    ENV.fetch("GITHUB_REF_NAME")
  end

  def build_id
    ENV.fetch("GITHUB_RUN_ID")
  end

  def git_repository
    ENV.fetch("GITHUB_REPOSITORY")
  end

  def server_url
    ENV.fetch("GITHUB_SERVER_URL")
  end

  def job_url
    "#{server_url}/#{git_repository}/actions/runs/#{build_id}"
  end

  def retrieve_release_tag
    tag = ENV.fetch("INPUT_RELEASE-TAG")

    re = tag.match(/^(release|dev)-(\d{8}).(\d+)-(\w+)$/)

    {
      image_tag: re[0],
      prefix: re[1],
      date: re[2],
      iteration: re[3],
      commit_sha: re[4]
    }
  end

  def set_output(name, value)
    File.write(ENV["GITHUB_OUTPUT"], "#{name}=#{value}", mode: "a+")
  end

  def append_step_summary(message)
    File.write(ENV["GITHUB_STEP_SUMMARY"], message, mode: "a+")
  end
end

Builds.new.run!
