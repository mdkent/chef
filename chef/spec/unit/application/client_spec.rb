#
# Author:: AJ Christensen (<aj@junglist.gen.nz>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Application::Client, "initialize" do
  before do
    @app = Chef::Application::Client.new
  end
  
  it "should create an instance of Chef::Application::Client" do
    @app.should be_kind_of(Chef::Application::Client)
  end
end

describe Chef::Application::Client, "reconfigure" do
  before do
    @app = Chef::Application::Client.new
    @app.stub!(:configure_opt_parser).and_return(true)
    @app.stub!(:configure_chef).and_return(true)
    @app.stub!(:configure_logging).and_return(true)
    Chef::Config.stub!(:[]).with(:json_attribs).and_return(false)
  end
  
  describe "with an splay value" do
    before do
      Chef::Config.stub!(:[]).with(:splay).and_return(60)
      Chef::Config.stub!(:[]).with(:interval).and_return(10)
    end
    
    it "should set the delay based on the interval and splay values" do
      Chef::Config.should_receive(:[]=).with(:delay, an_instance_of(Fixnum))
      @app.reconfigure
    end
  end
  
  describe "without an splay value" do
    before do
      Chef::Config.stub!(:[]).with(:splay).and_return(nil)
      Chef::Config.stub!(:[]).with(:interval).and_return(10)
    end
    
    it "should set the delay based on the interval" do
      Chef::Config.should_receive(:[]=).with(:delay, 10)
      @app.reconfigure
    end
  end

end

describe Chef::Application::Client, "reconfigure" do
  before do
    @app = Chef::Application::Client.new
    @app.stub!(:configure_opt_parser).and_return(true)
    @app.stub!(:configure_chef).and_return(true)
    @app.stub!(:configure_logging).and_return(true)
    Chef::Config.stub!(:[]).with(:interval).and_return(10)
    Chef::Config.stub!(:[]).with(:splay).and_return(nil)
  end

  describe "when the json_attribs configuration option is specified" do
    before do
      Chef::Config.stub!(:[]).with(:json_attribs).and_return("/etc/chef/dna.json")
      @json = mock("Tempfile", :read => {:a=>"b"}.to_json, :null_object => true)
      @app.stub!(:open).with("/etc/chef/dna.json").and_return(@json)
    end
    
    it "should parse the json out of the file" do
      JSON.should_receive(:parse).with(@json.read)
      @app.reconfigure
    end
    
    describe "when parsing fails" do
      before do
        JSON.stub!(:parse).with(@json.read).and_raise(JSON::ParserError)
        Chef::Application.stub!(:fatal!).and_return(true)
      end
      
      it "should hard fail the application" do
        Chef::Application.should_receive(:fatal!).with("Could not parse the provided JSON file (/etc/chef/dna.json)!: JSON::ParserError", 2).and_return(true)
        @app.reconfigure
      end
    end
  end
end

describe Chef::Application::Client, "setup_application" do
  before do
    Chef::Daemon.stub!(:change_privilege).and_return(true)
    @chef_client = mock("Chef::Client", :null_object => true)
    Chef::Client.stub!(:new).and_return(@chef_client)
    @app = Chef::Application::Client.new
    # this is all stuff the reconfigure method needs
    @app.stub!(:configure_opt_parser).and_return(true)
    @app.stub!(:configure_chef).and_return(true)
    @app.stub!(:configure_logging).and_return(true)
    Chef::Config.stub!(:[]).with(:interval).and_return(false)
    Chef::Config.stub!(:[]).with(:splay).and_return(false)
    Chef::Config.stub!(:[]).with(:recipe_url).and_return(false)
    Chef::Config.stub!(:[]).with(:json_attribs).and_return("/etc/chef/dna.json")
    Chef::Config.stub!(:[]).with(:user).and_return(nil)
    @json = mock("Tempfile", :read => {:a=>"b"}.to_json, :null_object => true)
    @app.stub!(:open).with("/etc/chef/dna.json").and_return(@json)
  end
  
  it "should change privileges" do
    Chef::Daemon.should_receive(:change_privilege).and_return(true)
    @app.setup_application
  end
  
  it "should instantiate a chef::client object" do
    Chef::Client.should_receive(:new).and_return(@chef_client)
    @app.setup_application
  end
  
  it "should assign the json attributes to the chef client instance" do
    @chef_client.should_receive(:json_attribs=).with({"a"=>"b"}).and_return(true)
    @app.reconfigure
    @app.setup_application
  end
  
  it "should assign the validation token to the chef client instance" do
    Chef::Config.stub!(:[]).with(:validation_token).and_return("testtoken")
    @chef_client.should_receive(:validation_token=).with("testtoken").and_return(true)
    @app.setup_application
  end
  
  it "should assign the node name to the chef client instance" do
    Chef::Config.stub!(:[]).with(:node_name).and_return("testnode")
    @chef_client.should_receive(:node_name=).with("testnode").and_return(true)
    @app.setup_application
  end
    
  after do
    Chef::Config[:solo] = false
  end
end
