require "helper/acceptance"

class GitHubTest < Test::Unit::AcceptanceTestCase
  include DataMapper::Sweatshop::Unique

  story <<-EOF
    As a project owner,
    I want to be able to use GitHub as a build triggerer
    So that my project is built everytime I push to the Holy Hub
  EOF

  def payload(repo)
    { "after"      => repo.head, "ref" => "refs/heads/#{repo.branch}",
      "repository" => { "url" => repo.uri },
      "commits"    => repo.commits }.to_json
  end

  def github_post(payload)
    post "/push/#{Integrity.app.github_token}", :payload => payload
  end

  scenario "Without any configured endpoint" do
    @_rack_mock_sessions = nil
    @_rack_test_sessions = nil
    Integrity.app.disable(:github_token)

    repo = git_repo(:my_test_project)
    Project.gen(:my_test_project, :uri => repo.uri)

    post("/push/foo", :payload => payload(repo)) { |r| assert r.not_found? }
    post("/push/",    :payload => payload(repo)) { |r| assert r.not_found? }
  end

  scenario "Receiving a payload for a branch that is not monitored" do
    repo = git_repo(:my_test_project)
    Project.gen(:my_test_project, :uri => repo.uri, :branch => "wip")

    github_post payload(repo)
    visit "/my-test-project"

    assert_contain("No builds for this project")
  end

  scenario "Receiving a payload with build_all option *enabled*" do
    stub(Time).now { unique { |i| Time.mktime(2009, 12, 15, i / 60, i % 60) } }
    Integrity.configure { |c| c.build_all = true }

    repo = git_repo(:my_test_project)
    3.times{|i| i % 2 == 1 ? repo.add_successful_commit : repo.add_failing_commit}
    Project.gen(:my_test_project, :uri => repo.uri, :command => "true")

    github_post payload(repo)
    assert_equal "4", last_response.body

    visit "/my-test-project"

    assert_have_tag("h1", :content => "Built #{repo.short_head} successfully")
    assert_have_tag(".attribution", :content => "by John Doe")
    assert_have_tag("#previous_builds li", :count => 3)
  end

  scenario "Receiving a payload with build_all option *disabled*" do
    Integrity.configure { |c| c.build_all = false }

    repo = git_repo(:my_test_project)
    repo.add_failing_commit
    repo.add_successful_commit
    Project.gen(:my_test_project, :uri => repo.uri)

    github_post payload(repo)
    assert_equal "1", last_response.body

    visit "/my-test-project"

    assert_have_tag("h1", :content => "Built #{repo.short_head} successfully")
    assert_have_no_tag("#previous_builds li")
  end

  scenario "Receiving an invalid payload" do
    Project.gen(:my_test_project, :uri => git_repo(:my_test_project).uri)
    basic_authorize "admin", "test"
    github_post "foo"
    assert last_response.client_error?
  end
end
