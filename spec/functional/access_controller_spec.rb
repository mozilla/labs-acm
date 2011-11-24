require File.expand_path("../../spec_helper", __FILE__)

require "rack/test"

describe ACM::Controller::ApiController do
  include Rack::Test::Methods

  def app
    @app ||= ACM::Controller::RackController.new
  end

  describe "check access" do

    before (:each) do
      @logger = ACM::Config.logger
      @permission_set_service = ACM::Services::PermissionSetService.new()

      @permission_set_service.create_permission_set(:name => :app_space,
                                                    :permissions => [:read_appspace, :write_appspace, :delete_appspace],
                                                    :additional_info => "this is the permission set for the app space")
      @user1 = SecureRandom.uuid
      @user2 = SecureRandom.uuid
      @user3 = SecureRandom.uuid
      @user4 = SecureRandom.uuid

      basic_authorize "admin", "password"

      object_data = {
        :name => "www_staging",
        :permission_sets => ["app_space"],
        :additionalInfo => "{component => cloud_controller}",
        :acl => {
          :read_appspace => ["u:#{@user1}", "u:#{@user2}", "u:#{@user3}", "u:#{@user4}"],
          :write_appspace => ["u:#{@user2}", "u:#{@user3}"],
          :delete_appspace => ["u:#{@user4}"]
         }
      }

      post "/objects", {}, { "CONTENT_TYPE" => "application/json", :input => object_data.to_json() }
      @logger.debug("post /objects last response #{last_response.inspect}")
      last_response.status.should eql(200)
      last_response.original_headers["Content-Type"].should eql("application/json;charset=utf-8")
      last_response.original_headers["Content-Length"].should_not eql("0")

      @object = Yajl::Parser.parse(last_response.body, :symbolize_keys => true)

    end

    it "will return a 200 if access is granted" do
      get "/objects/#{@object[:id]}/access?id=#{@user2}&p=read_appspace&p=write_appspace", {}, { "CONTENT_TYPE" => "application/json" }
      @logger.debug("get /objects/#{@object[:id]}/access last response #{last_response.inspect}")
      last_response.status.should eql(200)

    end

    it "will return a 404 for an empty subject" do
      get "/objects/#{@object[:id]}/access?p=read_appspace&p=write_appspace", {}, { "CONTENT_TYPE" => "application/json" }
      @logger.debug("get /objects/#{@object[:id]}/access last response #{last_response.inspect}")
      last_response.status.should eql(404)

    end

    it "will return a 404 for no permissions" do
      get "/objects/#{@object[:id]}/access?id=#{@user1}", {}, { "CONTENT_TYPE" => "application/json" }
      @logger.debug("get /objects/#{@object[:id]}/access last response #{last_response.inspect}")
      last_response.status.should eql(404)

    end

    it "will return a 404 for no subject or permissions" do
      get "/objects/#{@object[:id]}/access", {}, { "CONTENT_TYPE" => "application/json" }
      @logger.debug("get /objects/#{@object[:id]}/access last response #{last_response.inspect}")
      last_response.status.should eql(404)

    end

    it "will return a 404 for permissions that do not exist" do
      get "/objects/#{@object[:id]}/access?id=#{@user2}&p=read_appspace&p=some_random_permission", {}, { "CONTENT_TYPE" => "application/json" }
      @logger.debug("get /objects/#{@object[:id]}/access last response #{last_response.inspect}")
      last_response.status.should eql(404)

    end

    it "will return a 404 if there are existing permissions that do not apply to this user" do
      get "/objects/#{@object[:id]}/access?id=#{@user2}&p=read_appspace&p=delete_appspace", {}, { "CONTENT_TYPE" => "application/json" }
      @logger.debug("get /objects/#{@object[:id]}/access last response #{last_response.inspect}")
      last_response.status.should eql(404)

    end

    it "will return a 404 for an object that does not exist" do
      get "/objects/12345/access?id=#{@user1}&p=read_appspace&p=write_appspace", {}, { "CONTENT_TYPE" => "application/json" }
      @logger.debug("get /objects/12345/access last response #{last_response.inspect}")
      last_response.status.should eql(404)

    end

    it "will return a 404 for a user that does not exist" do
      get "/objects/#{@object[:id]}/access?id=55555&p=read_appspace&p=write_appspace", {}, { "CONTENT_TYPE" => "application/json" }
      @logger.debug("get /objects/#{@object[:id]}/access last response #{last_response.inspect}")
      last_response.status.should eql(404)

    end

    it "will return a 404 if the user is in one ace but not the other" do
      get "/objects/#{@object[:id]}/access?id=#{@user1}&p=read_appspace&p=write_appspace", {}, { "CONTENT_TYPE" => "application/json" }
      @logger.debug("get /objects/#{@object[:id]}/access last response #{last_response.inspect}")
      last_response.status.should eql(404)

    end

    it "will return a 404 if the user is in neither of the aces" do
      get "/objects/#{@object[:id]}/access?id=44444&p=read_appspace&p=write_appspace", {}, { "CONTENT_TYPE" => "application/json" }
      @logger.debug("get /objects/#{@object[:id]}/access last response #{last_response.inspect}")
      last_response.status.should eql(404)

    end


  end

end