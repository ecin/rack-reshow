jQuery(document).ready( function(){ 

  jQuery.extend( jQuery.easing, {
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

  var __reshow__ = {
    prev: function(){
      var active = jQuery('.__reshow_active__');
      var el = jQuery(this);
      if(active.prev().length > 0){
        active.animate({opacity: 0},
          {
            complete: function(){
              active.css('display', 'none');
              active.toggleClass('__reshow_active__')
              active = active.prev('.__reshow_body__');
              active.toggleClass( '__reshow_active__')
              active.css('opacity', 0);
              active.css('display', 'block');
              active.animate({opacity: 1});
              var version = Number(jQuery('#__reshow_version__').text());
              jQuery('#__reshow_version__').text( '0' + (version - 1));
              // Okay, bind the click again.
              el.one('click', __reshow__.prev);
            }
          });
        } else{
          el.one('click', __reshow__.prev);
        }
      },
      next: function(){
        var active = jQuery('.__reshow_active__');
        var el = jQuery(this);
        if(active.next().length > 0){
          active.animate({opacity: 0},
            {
              complete: function(){
                active.css('display', 'none');
                active.toggleClass('__reshow_active__')
                active = active.next()
                active.toggleClass( '__reshow_active__')
                active.css('opacity', 0);
                active.css('display', 'block');
                active.animate({opacity: 1});
                var version = Number(jQuery('#__reshow_version__').text());
                jQuery('#__reshow_version__').text( '0' + (version + 1));
                // Okay, bind the click again.
                el.one('click', __reshow__.next);
              }
            });
          } else{
            el.one('click', __reshow__.next);
          }
        }
      };

      jQuery('.__reshow_body__:last').toggleClass('__reshow_active__');
      jQuery('#__reshow_prev__').one('click', __reshow__.prev);
      jQuery('#__reshow_next__').one('click', __reshow__.next);
      jQuery('#__reshow_info__').click( function(){
        console.log("To be replaced with a Swift.js tooltip.");
      });

      var bar = jQuery('#__reshow_bar__');

      setTimeout(function(){
        bar.animate({'top': 0}, 'slow', 'easeOutBounce').animate({'opacity': 0.3},
        {
          complete: function(){
            bar.bind('mouseover', function(){
              jQuery(this).stop().animate({'opacity': 1});
            });

            bar.bind('mouseout', function(){
              jQuery(this).stop().animate({'opacity': 0.3});
            });
          }
        });
        }, 1000);

      });
