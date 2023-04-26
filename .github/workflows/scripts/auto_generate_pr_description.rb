#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'base64'

class AutoGeneratePrDescription
  def initialize(github_token, repository, pull_request_number, chat_gpt_api_key, jira_token)
    @github_token = github_token
    @repository = repository
    @pull_request_number = pull_request_number
    @chat_gpt_api_key = chat_gpt_api_key
    @jira_token = jira_token
  end

  def run
    # Get the pull request details
    pull_request = get_pull_resquest
    # Get the list of files in the pull request
    files = get_pull_request_files
    pr_code_contents = []
    # For each file, get its contents and generate a code review
    files.each do |file|
      next unless file["status"] == 'added' || file["status"] == 'modified'
      file_contents = get_file_contents(file["contents_url"])
      pr_code_contents << {content: file_contents, file_name: file["filename"]}
    end
    pp "Show me pull request", pull_request
    pp "Show me match", pull_request["title"].match(/\[(?<jira_id>[A-Z]+-\d+)\]/)
    jira_ticket_id = pull_request["title"].match(/\[(?<jira_id>[A-Z]+-\d+)\]/)[:jira_id]
    jira_ticket_desc = get_jira_issue_description(jira_ticket_id)
    pr_description = generate_pr_description(jira_ticket_desc, pr_code_contents) unless pr_code_contents.empty?
    create_pr_description(pr_description)
  end

  private

  def get_file_contents(contents_url)
    uri = URI.parse(contents_url)
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "token #{@github_token}"
    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true
    response = http.request(request)
    Base64.decode64(JSON.parse(response.body)['content'])
  end

  def get_jira_issue_description(jira_ticket_id)
    return "" if jira_ticket_id.blank?

    uri = URI.parse("https://mtrepanier.atlassian.net/rest/api/2/issue/#{jira_ticket_id}?fields=description")
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Basic #{@jira_token}"
    request['Content-Type'] = 'application/json'
    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true
    response = http.request(request)
    JSON.parse(response.body)["fields"]["description"]
  end

  def generate_pr_description(jira_ticket_desc, pr_code_contents)
    content = "Can you generate a GitHub pull request description for a pull request that contain this code?:"
    
    pr_code_contents.each_with_index do |pr_code_content, index|
      content = "#{content}\n\nAnd this block of code:" if index > 0
      content = "#{content}\n```\n #{pr_code_content[:content]}\n```"
    end

    content = "#{content}\n\nand that was implemented based on the this jira issue description:\n\n#{jira_ticket_desc}" unless jira_ticket_desc.blank?

    uri = URI.parse('https://api.openai.com/v1/chat/completions')
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@chat_gpt_api_key}"
    request['Content-Type'] = 'application/json'
    request.body = {
      model: "gpt-3.5-turbo",
      messages: [{"role": "user", "content": content}],
      temperature: 0.5,
      n: 1
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, :read_timeout => 500, :use_ssl => true) {|http| http.request(request)}
    pp "Show PR description received", response.body
    JSON.parse(response.body)['choices'][0]['message']["content"]
  end

  def create_pr_description(pr_description)
    uri = URI.parse("https://api.github.com/repos/#{@repository}/pulls/#{@pull_request_number}")
    request = Net::HTTP::Patch.new(uri)
    request['Authorization'] = "Bearer #{@github_token}"
    request['Content-Type'] = 'application/json'
    request.body = {
      body:pr_description
    }.to_json
    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true
    response = http.request(request)
  end

  def get_pull_resquest
    uri = URI.parse("https://api.github.com/repos/#{@repository}/pulls/#{@pull_request_number}")
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{@github_token}"
    request['Content-Type'] = 'application/json'
    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true
    response = http.request(request)
    JSON.parse(response.body)
  end

  def get_pull_request_files
    uri = URI.parse("https://api.github.com/repos/#{@repository}/pulls/#{@pull_request_number}/files")
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{@github_token}"
    request['Content-Type'] = 'application/json'
    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true
    response = http.request(request)
    JSON.parse(response.body)
  end
end

github_token = ARGV[0]
repository = ARGV[1]
pull_request_number = ARGV[2].to_i
api_key = ARGV[3]
jira_api_key = ARGV[4]

generate_pr_description = AutoGeneratePrDescription.new(github_token, repository, pull_request_number, api_key, jira_api_key)
generate_pr_description.run
