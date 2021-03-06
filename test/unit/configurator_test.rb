require "helper"

class ConfiguratorTest < Test::Unit::TestCase
  test "builder" do
    Integrity.configure { |c| c.builder(:threaded, 1) }
    assert_respond_to Integrity.builder, :wait!

    assert_raise(ArgumentError) {
      Integrity.configure { |c| c.builder :foo }
    }
  end

  test "directory" do
    Integrity.configure { |c| c.directory = "/tmp/builds" }
    assert_equal "/tmp/builds", Integrity.directory.to_s
  end

  test "base_uri and base_url" do
    Integrity.configure { |c| c.base_uri = "http://example.org" }
    assert_equal "http://example.org", Integrity.base_url.to_s

    Integrity.configure { |c| c.base_url = "http://foo.com" }
    assert_equal "http://foo.com", Integrity.base_url.to_s

    Integrity.base_url = nil
    assert_nothing_raised { Integrity.app }
  end

  test "log" do
    Integrity.configure { |c| c.log = "test.log" }
    assert_equal "test.log", Integrity.logger.
      instance_variable_get(:@logdev).
      instance_variable_get(:@dev).path
  end

  test "push and github_token" do
    Integrity.configure { |c| c.push :github, "MY_TOKEN" }
    assert_equal "MY_TOKEN", Integrity::App.github_token

    Integrity.configure { |c| c.github_token "HOLY_HUB" }
    assert_equal "HOLY_HUB", Integrity::App.github_token
  end
end
