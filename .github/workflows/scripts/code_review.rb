require 'net/http'
require 'json'
require 'octokit'

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
    head_sha = pull_request.head.sha

    # Get the list of files in the pull request
    files = @client.pull_request_files(@repository, @pull_request_number)

    # For each file, get its contents and generate a code review
    files.each do |file|
      next unless file.status == 'added' || file.status == 'modified'

      file_contents = get_file_contents(file.contents_url)
      class_name = get_class_name(file.filename)
      code_review = generate_code_review(class_name, file_contents)

      # Create a review comment for the file
      create_review_comment(file.filename, code_review, head_sha)
    end
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

  def get_class_name(filename)
    File.basename(filename, '.*')
  end

  def generate_code_review(class_name, file_contents)
    uri = URI.parse('https://api.openai.com/v1/engines/davinci-codex/completions')
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@chat_gpt_api_key}"
    request['Content-Type'] = 'application/json'
    request.body = {
      prompt: "Review the following code for class #{class_name}:\n\n#{file_contents}",
      max_tokens: 256,
      temperature: 0.5,
      n: 1,
      stop: ['\n']
    }.to_json
    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true
    response = http.request(request)
    JSON.parse(response.body)['choices'][0]['text']
  end

  def create_review_comment(filename, code_review, head_sha)
    @client.create_pull_request_review(
      @repository,
      @pull_request_number,
      body: "## Code Review for #{filename}\n\n#{code_review}",
      commit_id: head_sha,
      path: filename,
      position: 1
    )
  end
end

github_token = ARGV[0]
repository = ARGV[1]
pull_request_number = ARGV[2].to_i
api_key = ARGV[3]

code_review = CodeReview.new(github_token, repository, pull_request_number, api_key)
code_review.run
