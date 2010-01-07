require 'pstore'
require 'rack/static'

module Rack
  class Reshow

    class RackStaticBugAvoider
      def initialize(app, static_app)
        @app = app
        @static_app = static_app
      end

      def call(env)
        if env["PATH_INFO"]
          @static_app.call(env)
        else
          @app.call(env)
        end
      end
    end
    
    @@store_file = 'reshow.ps'
    
    def initialize( app, opts = {} )
      root = Object::File.expand_path(Object::File.dirname(__FILE__))
      @app = RackStaticBugAvoider.new(app, Rack::Static.new(app, :urls => ["/__reshow__"], :root => root))
      @store = PStore.new(@@store_file)
    end
    
    def call( env )
      status, headers, body = @app.call(env)
      request = Request.new(env)
      if request.get? and status == 200
        path = request.path
        if body.respond_to? :join
          body = body.join
          @store.transaction do |store|
            store[path] ||= []
            content = body.scan(/<body>(.*?)<\/body>/m).flatten.first
            store[path] << content unless content.nil? or store[path].last.eql?(content)
            body.sub! /<body>.*<\/body>/m, %q{<body><div id="__reshow_bodies__"></div></body>}
            store[path].reverse.each do |c|
              prepend_to_tag '<div id="__reshow_bodies__">', body, tag(:div, c, :class => '__reshow_body__')
            end
            insert_reshow_bar body, store[path].size
          end
          headers['Content-Length'] = body.length.to_s
          body = [body]
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

    private

    def prepend_to_tag(tag, page, string)
      page.sub! /#{tag}/, "#{tag}\n" + string
    end
    
    def append_to_tag(tag, page, string)
      page.sub! /#{tag}/, string + "\n#{tag}"
    end

    def insert_reshow_bar(page, versions)
      append_to_tag '</head>', page, style
      append_to_tag '</head>', page, jquery
      append_to_tag '</head>', page, javascript
      append_to_tag '</body>', page, toolbar(versions)  
    end

    def tag(type, body, options={})
      options = options.map {|key, value| "#{key}=\"#{value}\""}.join(' ')
      <<-EOF
      <#{type} #{options}">
        #{body}
      </#{type}>
      EOF
    end

    def toolbar(versions)
      versions = (versions < 10 ? '0' : '') + versions.to_s
      <<-EOF
        <div id="__reshow_bar__">
          <span id="__reshow_version__">#{versions}</span>
          <span style="margin-right: 10px;">
            <img id="__reshow_prev__" src="/__reshow__/action_back.gif" style="margin-right: 7px;"/>
            <img id="__reshow_next__" src="/__reshow__/action_forward.gif" />
          </span>
          <span><img id="__reshow_info__" src="/__reshow__/icon_alert.gif" /></span>
        </div>
      EOF
    end

    def style
      %q{<link charset='utf-8' href="/__reshow__/reshow.css" rel='stylesheet' type='text/css'>}
    end

    def javascript
      %q{<script src="/__reshow__/reshow.js"></script>}
    end

    def jquery
      %q{<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js"></script>}
    end
    
  end
end