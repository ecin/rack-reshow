require 'pstore'

module Rack
  class Reshow
    
    @@store_file = 'reshow.ps'
    
    def initialize( app, opts = {} )
      @app = app
      @store = PStore.new(@@store_file)
    end
    
    def call( env )
      status, headers, body = @app.call(env)
      request = Request.new(env)
      if request.get?
        path = request.path
        if version = request.params['__reshow__']
          body = @store.transaction do |store|
            store[path][version.to_i-1]
          end
        else
          @store.transaction do |store|
            store[path] ||= []
            store[path] << body unless body.nil? or store[path].last.eql?(body)
          end
        end
      end
      [status, headers, body]
    end
    
    def []( path )
      @store.transaction(true) {|store| store[path] || Array.new}
    end
    
    def purge!
      Object::File.delete(@@store_file) if Object::File.exists?(@@store_file)
    end
    
  end
end
