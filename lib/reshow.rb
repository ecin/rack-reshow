require 'pstore'

module Rack
  class Reshow
    
    @@store_file = 'reshow.ps'
    
    def initialize( app, opts = {} )
      @app = app
      @store = PStore.new(@@store_file)
    end
    
    def call( env )
      response = @app.call(env)
      body = response.last
      request = Request.new(env)
      if request.get?
        path = request.path
        @store.transaction do |store|
          store[path] ||= []
          store[path] << body unless body.nil? or store[path].last.eql?(body)
        end
      end
      response
    end
    
    def []( path )
      @store.transaction(true) {|store| store[path]}
    end
    
    def purge!
      Object::File.delete(@@store_file) if Object::File.exists?(@@store_file)
    end
    
  end
end