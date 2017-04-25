(function () {

  function init() {
    $('pre').each(function (i, e) { var n = $(e); n.html($.trim(n.html().replace(/</g, '&lt;'))) });
  }

  jQuery(function() { init(); });
}());
