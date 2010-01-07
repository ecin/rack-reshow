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
      if request.get?
        path = request.path
        if version = request.params['__reshow__']
          body = @store.transaction(true) do |store|
            store[path][version.to_i-1]
          end
        elsif body.respond_to? :join
          body = body.join
          insert_reshow_bar(body)
          @store.transaction do |store|
            store[path] ||= []
            content = body.scan(/<body>(.*?)<\/body>/m).flatten.first
            store[path] << content unless content.nil? or store[path].last.eql?(content)
            body.sub! /<body>.*<\/body>/m, "<body></body>"
            store[path].each do |c|
              insert_into_body body, tag(:div, c, :class => '__reshow_body__')
            end
          end
          headers['Content-Length'] = body.length.to_s
        end
      end
      [status, headers, [body]]
    end
    
    def []( path )
      @store.transaction(true) {|store| store[path] || Array.new}
    end
    
    def purge!
      Object::File.delete(@@store_file) if Object::File.exists?(@@store_file)
    end

    private

    def insert_into_body(page, string)
      page.sub! /<\/body>/, string + "\n</body>"
    end

    def insert_into_head(page, string)
      page.sub! /<\/head>/, string + "\n</head>"
    end

    def insert_reshow_bar(page)
      insert_into_head page, style
      insert_into_head page, jquery
      insert_into_head page, javascript
      insert_into_body page, toolbar  
    end

    def tag(type, body, options={})
      options = options.map {|key, value| "#{key}=\"#{value}\""}.join(' ')
      <<-EOF
      <#{type} #{options}">
        #{body}
      </#{type}>
      EOF
    end

    def toolbar
      <<-EOF
        <div id="__reshow_bar__">
          <span id="__reshow_version__" style="font-weight: bold; margin-right: 10px; color: steelblue">03</span>
          <span style="margin-right: 10px;">
            <img id="__reshow_prev__" src="/__reshow__/action_back.gif" style="margin-right: 7px;"/>
            <img id="__reshow_next__" src="/__reshow__/action_forward.gif" />
          </span>
          <span><img id="__reshow_info__" src="/__reshow__/icon_alert.gif" /></span>
        </div>
      EOF
    end

    def style
      <<-EOF
        <style id="__reshow_bar_style__">
          #__reshow_bar__{
            padding: 3px 15px 3px 15px;
            margin: 0;
            font-family: helvetica;
            text-align: center;
            position: fixed;
            top: -25px;
            left: 3%;
            height: 25px;
            background: url(/__reshow__/border.png) white repeat-x bottom left;
            border-left: 1px solid #ccc;
            border-right: 1px solid #ccc;
            z-index: 1024;
          }

          #__reshow_bar__ img{
            cursor: pointer;
            position: relative;
            top: 3px;
          }

          .__reshow_body__{
            opacity: 0;
            display: none;
          }

          .__reshow_active__{
            opacity: 1;
            display: block;
          }
        </style>
      EOF
    end

    def javascript
      <<-EOF
      <script>
      jQuery(document).ready( function(){ 

      var __reshow__ = {version: 03};

      jQuery.extend( jQuery.easing,
      {
        'easeOutBounce': function(x, t, b, c, d) {
        		if ((t/=d) < (1/2.75)) {
        			return c*(7.5625*t*t) + b;
        		} else if (t < (2/2.75)) {
        			return c*(7.5625*(t-=(1.5/2.75))*t + .75) + b;
        		} else if (t < (2.5/2.75)) {
        			return c*(7.5625*(t-=(2.25/2.75))*t + .9375) + b;
        		} else {
        			return c*(7.5625*(t-=(2.625/2.75))*t + .984375) + b;
        		}
        	}
        });

        jQuery('#__reshow_prev__').click( function(){
          var active = jQuery('.__reshow_active__');
          if(active.prev().length > 0){
            active.animate({opacity: 0},
              {
                complete: function(){
                  active.css('display', 'none');
                  active.toggleClass('__reshow_active__')
                  active = active.prev();
                  active.toggleClass( '__reshow_active__')
                  active.css('opacity', 0);
                  active.css('display', 'block');
                  active.animate({opacity: 1});
                  __reshow__['version'] -= 1; 
                  jQuery('#__reshow_version__').text( '0' + __reshow__['version'] );
                }
              });
          }
        });


        jQuery('#__reshow_next__').click( function(){
          var active = jQuery('.__reshow_active__');
          if(active.next().length > 0){
            active.animate({opacity: 0},
              {
                complete: function(){
                  active.css('display', 'none');
                  active.toggleClass('__reshow_active__')
                  active = active.next();
                  active.toggleClass( '__reshow_active__')
                  active.css('opacity', 0);
                  active.css('display', 'block');
                  active.animate({opacity: 1});
                  __reshow__['version'] += 1;
                  jQuery('#__reshow_version__').text( '0' + __reshow__['version'] );
                }
              });
          }
        });

        jQuery('#__reshow_info__').click( function(){
          console.log("To be replaced with a Swift.js tooltip.");
        });

        var bar = jQuery('#__reshow_bar__');

        setTimeout(function(){
          bar.animate({'top': 0}, 'slow', 'easeOutBounce').animate({'opacity': 0.3},
          {
            complete: function(){
              bar.mouseenter( function(){
                jQuery(this).stop().animate({'opacity': 1});
              });

              bar.mouseleave( function(){
                jQuery(this).stop().animate({'opacity': 0.3});
              });
            }
          });
          }, 1000);

          });
          </script>
      EOF
    end

    def jquery
      <<-EOF
        <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js"></script>
      EOF
    end
    
  end
end
