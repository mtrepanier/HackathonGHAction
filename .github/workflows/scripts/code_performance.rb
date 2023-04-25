#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'base64'

class CodePerformance
  def initialize(github_token, repository, pull_request_number, chat_gpt_api_key)
    @github_token = github_token
    @repository = repository
    @pull_request_number = pull_request_number
    @chat_gpt_api_key = chat_gpt_api_key
  end

  def run
    # Get the pull request details
    pull_request = get_pull_resquest
    # Get the list of files in the pull request
    files = get_pull_request_files
    code_performance_comments = []
    # For each file, get its contents and generate a code review
    files.each do |file|
      next unless file["status"] == 'added' || file["status"] == 'modified'
      file_contents = get_file_contents(file["contents_url"])
      code_performance = generate_code_performance(Base64.decode64(file_contents))
      code_performance_comments << {comment: code_performance, file_name: file["filename"]}
    end

    create_review_comments(code_performance_comments, pull_request["head"]["sha"])
  end

  private

  def get_file_contents(contents_url)
    uri = URI.parse(contents_url)
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "token #{@github_token}"
    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true
    response = http.request(request)
    JSON.parse(response.body)['content']
  end

  def generate_code_performance(file_contents)
    content = "Can you generate change to this code to optimize performance the following code:\n\n #{file_contents}"
    uri = URI.parse('https://api.openai.com/v1/chat/completions')
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@chat_gpt_api_key}"
    request['Content-Type'] = 'application/json'
    request.body = {
      model: "gpt-3.5-turbo",
      messages: [{"role": "user", "content": content}],
      temperature: 0.5,
      n: 1,
      stop: ['\n']
    }.to_json
    http = Net::HTTP.new(uri.hostname, uri.port, :read_timeout => 500)
    http.use_ssl = true
    response = http.request(request)
    pp "Generated code performance:", response.body
    JSON.parse(response.body)['choices'][0]['message']["content"]
  end

  def create_review_comments(code_review_comments, commit_sha)
    uri = URI.parse("https://api.github.com/repos/#{@repository}/pulls/#{@pull_request_number}/reviews")
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@github_token}"
    request['Content-Type'] = 'application/json'
    request.body = {
      commit_id: commit_sha,
      body: "This is code sugestion to optimize performance proposed by the ForbiddenFruit.",
      event: 'COMMENT',
      comments: code_review_comments.map { |c| { path: c[:file_name], position: 1, body: c[:comment] } }
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

code_performance = CodePerformance.new(github_token, repository, pull_request_number, api_key)
code_performance.run
