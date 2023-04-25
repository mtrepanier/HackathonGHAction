#!/usr/bin/env ruby

require 'net/http'
require 'json'

class CodeReview
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
    code_review_comments = []
    # For each file, get its contents and generate a code review
    files.each do |file|
      next unless file["status"] == 'added' || file["status"] == 'modified'
      code_review = generate_code_review(file["patch"])
      code_review_comments << {comment: code_review, file_name: file["filename"]}
    end

    create_review_comments(code_review_comments, pull_request["head"]["sha"])
  end

  private

  def generate_code_review(patch)
    uri = URI.parse('https://api.openai.com/v1/chat/completions')
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@chat_gpt_api_key}"
    request['Content-Type'] = 'application/json'
    request.body = {
      model: "gpt-3.5-turbo",
      messages: [{"role": "user", "content": "Can you do a code review the following code:\n\n #{patch}"}],
      temperature: 0.5,
      n: 1,
      stop: ['\n']
    }.to_json
    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true
    response = http.request(request)
    JSON.parse(response.body)['choices'][0]['message']["content"]
  end

  def create_review_comments(code_review_comments, commit_sha)
    uri = URI.parse("https://api.github.com/repos/#{@repository}/pulls/#{@pull_request_number}/reviews")
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@github_token}"
    request['Content-Type'] = 'application/json'
    request.body = {
      commit_id: commit_sha,
      body: "This is close to perfect! Please address the suggested inline change proposed by the ForbiddenFruit.",
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

code_review = CodeReview.new(github_token, repository, pull_request_number, api_key)
code_review.run
