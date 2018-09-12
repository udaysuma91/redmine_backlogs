$( document ).ready(function() {
  $('.single-sprint').each(function(i, el) {
    var capacity = $(this).children().find(".capacity-point").text();           
    if (capacity > 0){    
      var totalpoint = 0.0;
      $(this).children('ul').children('li').each(function () {
        var storypoint = $(this).attr('for');
        var storyid = $(this).attr('story');
        if (!(storypoint === undefined || storypoint === null || (isNaN(storypoint)))) {
          totalpoint += parseFloat(storypoint) || 0.0
          if(capacity < totalpoint && (totalpoint > 0.0)){
            $( "li#"+storyid).prev().css('border-bottom','3px solid red');
            return false;
          }
        }
      });
    }
  });
});