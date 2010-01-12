require 'pstore'
require 'rack/static'
require 'open-uri'

module Rack
  class Reshow
    
    class Page   

      class << self
        def tag(type, content, options={})
          options = options.map {|key, value| "#{key}=\"#{value}\""}.join(' ')
          <<-EOF
          <#{type} #{options}">
            #{content}
          </#{type}>
          EOF
        end
      end
      
      def initialize(html, path, app)
        @html = html
        @path = path
        self.stylesheets!(app)
      end
      
      def to_s
        @html
      end
      
      def head
        @html.scan(/<head>(.*?)<\/head>/m).flatten.first
      end
      
      def head=(content)
        @html.sub! /<head>.*<\/head>/m, "<head>#{content}</head>"
      end
      
      def body
        @html.scan(/<body>(.*?)<\/body>/m).flatten.first
      end
      
      def body=(content)
        @html.sub! /<body>.*<\/body>/m, "<body>#{content}</body>"
      end
      
      def stylesheets
        @stylesheets.each_value.to_a.join
      end
      
      def stylesheets!(app)
        @stylesheets ||= begin
          @stylesheets = {}
          links = head.scan(/<link.*?rel=['|"]+stylesheet['|"]+.*?>/)
          links.each do |link|
            href = link.scan(/href=['|"]+(.*?)['|"]+/).flatten.first
            if href[/https?:\/\//] 
              @stylesheets[href] = open(href).read
            else
              href = @path + href unless href[0] == ?/
              status, headers, body = app.call Rack::MockRequest.env_for(href)
              sheet = ''
              body.each {|part| sheet << part}
              @stylesheets[href] = sheet
            end
          end
          @stylesheets
        end
      end
      
      def length
        @html.length
      end
      
      def eql?(page)
        body == page.body and stylesheets == page.stylesheets
      end
      
      def prepend_to_tag(tag, string)
        @html.sub! /#{tag}/, "#{tag}\n" + string
      end

      def append_to_tag(tag, string)
        @html.sub! /#{tag}/, string + "\n#{tag}"
      end
      
    end

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
      request = Request.new(env)
      path = request.path
      return serve_stylesheet(request) if path =~ /__reshow__\/assets/
      status, headers, body = @app.call(env)
      if status == 200 and body.respond_to? :join
        body = body.join
        page = Page.new body, path, @app
        # Store response
        @store.transaction do |store|
          store[path] ||= []
          store[path] << page unless body.nil? or store[path].last.eql?(page)
        end
        # Insert Reshow assets
        page.append_to_tag '</head>', [style, javascript].join("\n")
        # Prepare for Reshow bar
        @store.transaction(true) do |store|
          page.body = %q{<div id="__reshow_bodies__"></div>}
          store[path].reverse.each do |p|
            page.prepend_to_tag '<div id="__reshow_bodies__">', Page.tag(:div, p.body, :class => '__reshow_body__')
          end
          versions = store[path].count
          # Insert Reshow Bar
          page.append_to_tag '</body>', toolbar(versions)
          # Insert versioned stylesheets
          versions.times do |v|
            escaped_path = Rack::Utils.escape(path)
            href = "/__reshow__/assets?path=#{escaped_path}&version=#{v}"
            page.append_to_tag '</head>', "<link charset='utf-8' href='#{href}' rel='stylesheet' type='text/css'>"
          end
        end
        headers['Content-Length'] = page.length
        body = [page.to_s]
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

    def serve_stylesheet(request)
      version = request.params['version'].to_i
      stylesheets = ''
      @store.transaction(true) do |store|
        stylesheets = store[request.params['path']][version].stylesheets
      end
      [200, {'Content-Length' => stylesheets.length.to_s, 'Content-Type' => 'text/css'}, [stylesheets]]
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
      <<-EOF
      <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js"></script>
      <script src="/__reshow__/reshow.js"></script>
      EOF
    end
  end
end
