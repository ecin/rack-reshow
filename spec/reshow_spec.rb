require 'rack'

require File.expand_path(File.dirname(__FILE__) + '/../lib/reshow.rb')

include Rack

# Need to change the app for some test cases
class Rack::Reshow; attr_accessor :app; end

describe Rack::Reshow do

  # Set up configuration variables

  before :all do
    @post_url = '/comments'
    @env = Rack::MockRequest.env_for '/'
    # The Lambdacat App
    @body = ["<body>Lambda, lambda, lambda app, hoooo!</body>"]
    @body2 = ["<body>Lambda app is on the run, lambda app is loose!</body>"]
    @app = lambda {|env| [200, {}, @body]}
  end

  # Rack::Reshow middleware can be instantiated
  it 'should accept an :app and an :opts hash at instantiation' do
    lambda { Reshow.new(@app, {}) }.should_not raise_error
  end
 
  before(:each) { @middleware = Reshow.new @app }

  it 'should return an array with stored versions given a path' do
    @middleware['/'].should be_empty
    @middleware.call @env
    @middleware['/'].size.should == 1
  end

  it 'should allow to purge the pstore' do
    @middleware.call @env
    @middleware['/'].should_not be_empty
    @middleware.purge!
    @middleware['/'].should be_empty 
  end

  after(:each) { @middleware.purge! }
  
  # Rack::Reshow#call is defined, as in any middleware
  it 'should return an array with status, headers, and body when sent :call' do
    response = @middleware.call @env
    response.class.should be(Array) 
    response.size.should == 3
    response[2] == @body.to_s.scan(/<body>(.*?)<\/body>/m).flatten.first
  end

  it 'should save a version of a page when the content changes' do
    @middleware.call @env
    @middleware.app = lambda {|env| [200, {}, @body2]}
    @middleware.call @env
    @middleware['/'].size.should == 2
    versions = @middleware['/']
    versions[0].should match("Lambda, lambda, lambda app, hoooo!")
    versions[1].should match("Lambda app is on the run, lambda app is loose!")
  end

  it 'should allow to view previous versions of a page' do
    @middleware.call @env
    @middleware.app = lambda {|env| [200, {}, @body2]}
    @middleware.call @env
    status, headers, body = @middleware.call Rack::MockRequest.env_for('/', {:input => "__reshow__=1"})
    body.to_s.should match("Lambda, lambda, lambda app, hoooo!")
    status, headers, body = @middleware.call Rack::MockRequest.env_for('/', {:input => "__reshow__=2"})
    body.to_s.should match("Lambda app is on the run, lambda app is loose!")
  end

  it 'should return all bodies in history (though hidden by css)' do
    @middleware.call @env
    @middleware.app = lambda {|env| [200, {}, @body2]}
    status, headers, body = @middleware.call @env
    body.to_s.should match(/Lambda app is on the run, lambda app is loose!/)
    body.to_s.should match(/Lambda, lambda, lambda app, hoooo!/) 
  end

end
