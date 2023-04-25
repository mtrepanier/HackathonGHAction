#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'octokit'
require 'base64'

class CodeReview
  def initialize(github_token, repository, pull_request_number, chat_gpt_api_key)
    @github_token = github_token
    @repository = repository
    @pull_request_number = pull_request_number
    @chat_gpt_api_key = chat_gpt_api_key
    @client = Octokit::Client.new(access_token: @github_token)
  end

  def run
    # Get the pull request details
    pull_request = @client.pull_request(@repository, @pull_request_number)

    # Get the list of files in the pull request
    files = @client.pull_request_files(@repository, @pull_request_number)
    code_review_comments = []
    # For each file, get its contents and generate a code review
    files.each do |file|
      next unless file.status == 'added' || file.status == 'modified'
      code_review = generate_code_review(file.patch)
      code_review_comments << {comment: code_review, file_name: file.filename}
    end

    create_review_comments(code_review_comments)
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

  def create_review_comments(code_review_comments)
    comments = []
    code_review_comments.each do |code_review_comment|
      comments << {path: code_review_comment[:file_name], position: 1, body: code_review_comment[:comment]}
    end
    options = {event: 'COMMENT', body: "This is close to perfect! Please address the suggested inline change proposed by the ForbiddenFruit.", comments: comments}
    @client.create_pull_request_review(@repository, @pull_request_number, options)
  end
end

github_token = ARGV[0]
repository = ARGV[1]
pull_request_number = ARGV[2].to_i
api_key = ARGV[3]

code_review = CodeReview.new(github_token, repository, pull_request_number, api_key)
code_review.run
