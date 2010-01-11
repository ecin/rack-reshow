require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

include Rack

# Need to change the app for some test cases
class Rack::Reshow; attr_accessor :app; end

describe Rack::Reshow do
  include Rack::Test::Methods

  # Set up configuration
  before :all do
    @root = Object::File.expand_path(Object::File.dirname(__FILE__))
    @env = Rack::MockRequest.env_for '/'
    @body = [File.open(@root + '/public/v1.html').read]
    @body2 = [File.open(@root + '/public/v2.html').read]
    @css = File.open(@root + '/public/v1.css').read
    @css2 = File.open(@root + '/public/v2.css').read
    app = lambda {|env| [200, {}, @body]}
    @app = Rack::Static.new(app, :urls => ["/public"], :@root => @root)
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
    response.last.should respond_to(:each)
  end

  it 'should save a version of a page when the content changes' do
    @middleware.call @env
    @middleware.app = lambda {|env| [200, {}, @body2]}
    @middleware.call @env
    @middleware['/'].size.should == 2
    versions = @middleware['/']
    versions[0].body.should match(/#{@body.to_s.scan(/<body>(.*?)<\/body>/m).flatten.first}/)
    versions[1].body.should match(/#{@body2.to_s.scan(/<body>(.*?)<\/body>/m).flatten.first}/)
  end

  it 'should return all bodies in history (though hidden by css)' do
    @middleware.call @env
    @middleware.app = lambda {|env| [200, {}, @body2]}
    status, headers, body = @middleware.call @env
    body.to_s.should match(/#{@body.join.scan(/<body>(.*?)<\/body>/m).flatten.first}/)
    body.to_s.should match(/#{@body2.join.scan(/<body>(.*?)<\/body>/m).flatten.first}/)
    body.to_s.scan(/class="__reshow_body__"/).count.should == 2
  end
  
  it 'should insert a <link> tag for each version in history' do
    status, headers, body = @middleware.call @env
    count = body.to_s.scan(/<link.*?>/).count
    @middleware.app = lambda {|env| [200, {}, @body2]}
    status, headers, body = @middleware.call @env
    body.to_s.scan(/<link.*?>/).count.should == count + 1
  end
  
  it 'should save external stylesheets and insert them as separate <link> tags' do
    status, headers, body = @middleware.call @env
    body.to_s.should match(/<link.*?href='\/__reshow__\/assets\?path=\%2F&version=0'.*?>/)
    app = lambda {|env| [200, {}, @body2]}
    @middleware.app = Rack::Static.new(app, :urls => ["/public"], :@root => @root)
    status, headers, body = @middleware.call @env
    body.to_s.should match(/<link.*?href='\/__reshow__\/assets\?path=\%2F&version=0'.*?>/)
    body.to_s.should match(/<link.*?href='\/__reshow__\/assets\?path=\%2F&version=1'.*?>/)
  end
  
  it 'should serve versioned stylesheets' do
    @middleware.call @env
    status, headers, body = @middleware.call Rack::MockRequest.env_for '/__reshow__/assets?path=%2F&version=0'
    body.to_s.should eql(@css)
  end
  
  it 'should insert a Reshow bar to allow users to view different versions' do
    status, headers, body = @middleware.call @env
    body.to_s[/id="__reshow_bar__"/].should_not be_nil
  end

end
