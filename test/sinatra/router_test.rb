require "minitest/autorun"
require "minitest/spec"
require "rack/test"
require "sinatra"

require_relative "../../lib/sinatra/router"

# suppress Sinatra
set :run, false

Apps = (0..3).map do |i|
  Sinatra.new do
    set :raise_errors, true
    set :show_exceptions, false

    get "/app#{i}" do
      headers["X-Cascade"] = "pass" if params[:pass] == "true"
      200
    end
  end
end

describe Sinatra::Router do
  include Rack::Test::Methods

  describe "as a rack app" do
    def app
      Sinatra::Router.new do
        route Apps[0]
        route Apps[1], lambda { |e| e["HTTP_X_COND1"] == "true" }

        with_conditions(lambda { |e| e["HTTP_X_COND2"] == "true" }) do
          route Apps[2]

          with_conditions(lambda { |e| e["HTTP_X_COND3"] == "true" }) do
            route Apps[3]
          end
        end

        run lambda { |env| [404, {}, []] }
      end
    end

    it "routes to an app" do
      get "/app0"
      assert_equal 200, last_response.status
    end

    it "responds with 404" do
      get "/not-found"
      assert_equal 404, last_response.status
    end

    it "passes through apps" do
      get "/app0", pass: true
      assert_equal 404, last_response.status
    end

    it "passes routing conditions" do
      header "X-Cond1", "true"
      get "/app1"
      assert_equal 200, last_response.status
    end

    it "fails routing conditions" do
      get "/app1"
      assert_equal 404, last_response.status
    end

    it "passes routing conditions in a block" do
      header "X-Cond2", "true"
      get "/app2"
      assert_equal 200, last_response.status
    end

    it "fails routing conditions in a block" do
      get "/app2"
      assert_equal 404, last_response.status
    end

    it "passes nested routing conditions" do
      header "X-Cond2", "true"
      header "X-Cond3", "true"
      get "/app3"
      assert_equal 200, last_response.status
    end

    it "fails nested routing conditions" do
      header "X-Cond2", "true"
      get "/app3"
      assert_equal 404, last_response.status
    end
  end

  describe "as middleware" do
    def app
      Rack::Builder.new do
        use Sinatra::Router do
          route Apps[0]
          route Apps[1], lambda { |e| e["HTTP_X_COND1"] == "true" }

          with_conditions(lambda { |e| e["HTTP_X_COND2"] == "true" }) do
            route Apps[2]

            with_conditions(lambda { |e| e["HTTP_X_COND3"] == "true" }) do
              route Apps[3]
            end
          end
        end

        run lambda { |env| [404, {}, []] }
      end
    end

    it "routes to an app" do
      get "/app0"
      assert_equal 200, last_response.status
    end

    it "responds with 404" do
      get "/not-found"
      assert_equal 404, last_response.status
    end

    it "passes routing conditions" do
      header "X-Cond1", "true"
      get "/app1"
      assert_equal 200, last_response.status
    end

    it "fails routing conditions" do
      get "/app1"
      assert_equal 404, last_response.status
    end

    it "passes routing conditions in a block" do
      header "X-Cond2", "true"
      get "/app2"
      assert_equal 200, last_response.status
    end

    it "fails routing conditions in a block" do
      get "/app2"
      assert_equal 404, last_response.status
    end

    it "passes nested routing conditions" do
      header "X-Cond2", "true"
      header "X-Cond3", "true"
      get "/app3"
      assert_equal 200, last_response.status
    end

    it "fails nested routing conditions" do
      header "X-Cond2", "true"
      get "/app3"
      assert_equal 404, last_response.status
    end
  end
end
