$(document).ready(function(){
  $('a[href*="#"]:not([href="#carouselHome"])').click(function() {
    if (location.pathname.replace(/^\//,'') == this.pathname.replace(/^\//,'') && location.hostname == this.hostname) {
      var target = $(this.hash);
      target = target.length ? target : $('[name=' + this.hash.slice(1) +']');
      if (target.length) {
        $('html, body').animate({
          scrollTop: target.offset().top
        }, 1000);
        return false;
      }
    }
  });
  $("#alert-app").fadeTo(4000,0.7).slideUp(1000, function(){
      $("#alert-app").alert('close');
  });
});
