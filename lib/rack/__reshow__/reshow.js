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
      var active = jQuery('div.__reshow_active__');
      var el = jQuery(this);
      var css = jQuery('link.__reshow_active__');
      if(active.prev().length > 0){
        active.animate({opacity: 0},
          {
            complete: function(){
              css.toggleClass('__reshow_active__');
              css[0].disabled = true;
              css = css.prev();
              css.toggleClass('__reshow_active__');
              css[0].disabled = false;
              active.css('display', 'none');
              active.toggleClass('__reshow_active__')
              active = active.prev('.__reshow_body__');
              active.toggleClass( '__reshow_active__')
              active.css('opacity', 0);
              active.css('display', 'block');
              active.animate({opacity: 1});
              var version = Number(jQuery('#__reshow_version__').text()) - 1;
              version = (version < 10 ? '0' : '') + version
              jQuery('#__reshow_version__').text(version);
              // Okay, bind the click again.
              if(active.prev().length > 0){
                // Okay, bind the click again.
                el.one('click', __reshow__.prev);
              } else{
                el.animate({opacity: 0.33});
              }
              jQuery('#__reshow_next__').animate({opacity: 1}).one('click', __reshow__.next);
            }
          });
        } else{
          el.one('click', __reshow__.prev);
        }
      },
      next: function(){
        var active = jQuery('div.__reshow_active__');
        var el = jQuery(this);
        var css = jQuery('link.__reshow_active__');
        if(active.next().length > 0){
          active.animate({opacity: 0},
            {
              complete: function(){
                css.toggleClass('__reshow_active__');
                css[0].disabled = true;
                css = css.next();
                css.toggleClass('__reshow_active__');
                css[0].disabled = false;
                active.css('display', 'none');
                active.toggleClass('__reshow_active__')
                active = active.next()
                active.toggleClass( '__reshow_active__')
                active.css('opacity', 0);
                active.css('display', 'block');
                active.animate({opacity: 1});
                var version = Number(jQuery('#__reshow_version__').text()) + 1;
                version = (version < 10 ? '0' : '') + version
                jQuery('#__reshow_version__').text(version);
                if(active.next().length > 0){
                  // Okay, bind the click again.
                  el.one('click', __reshow__.next);
                } else{
                  el.animate({opacity: 0.33});
                }
                jQuery('#__reshow_prev__').animate({opacity: 1}).one('click', __reshow__.prev);
              }
            });
          } else{
            el.one('click', __reshow__.next);
          }
        }
      };

      // Disable all stylesheets except for reshow.css

      jQuery('link[rel*=style]').each( function(){
        if(jQuery(this).attr('href') != '/__reshow__/reshow.css')
          this.disabled = true;
      });
      
      // Enable most recent stylesheet
      
      jQuery('link[rel*=style]:last').each( function(){
        this.disabled = false;
        jQuery(this).toggleClass('__reshow_active__');
      });

      // Bind initial clicks

      jQuery('.__reshow_body__:last').toggleClass('__reshow_active__');
      if(jQuery('div.__reshow_active__').prev().length > 0)
        jQuery('#__reshow_prev__').one('click', __reshow__.prev);
      else
        jQuery('#__reshow_prev__').css({opacity: 0.33});
      //jQuery('#__reshow_next__').one('click', __reshow__.next);
      jQuery('#__reshow_info__').click( function(){
        console.log("To be replaced with a Swift.js tooltip.");
      });

      // Bar animation

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
