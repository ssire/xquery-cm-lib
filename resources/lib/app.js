(function () {

  // Global network communication error handler (see also core/oppidum.js in AXEL-FORMS)
  // As per jQUery Ajax error callback data.status may be error, timeout, notmodified, parseerror
  // or per the application unexpected
  function networkErrorCb (event, data) {
    var msg;
    if (data.status === 'timeout') {
      msg = "The server is not answering. It is possible that your internet connexion is lost. The application will try to reload the page. Please check that your command hasn't been taken into account in spite of the absence of answer before submitting it again !";
      alert(msg);
      window.location.reload();
    } else {
      if (data.status === 'unexpected') {
        msg = "The server has returned an unexpected answer. Please check that your command hasn't been taken into account in spite of the unexpected answer before submitting it again !";
      } else {
        msg = $axel.oppidum.parseError(data.xhr, data.status, data.e);
      }
      alert(msg);
    }
  }
  
  function closeChoice2Popup (e) {
    // temporary hack the time 'choice2' handles this by itself
    var sel = $(e.target).closest('.axel-choice2'),
        target = sel.get(0);
    if (0 === sel.size()) {
      $('ul.choice2-popup1').removeClass('show');
    } else {
      $('.axel-choice2').filter( function (i,e) { return e !== target; }).children('ul.choice2-popup1').removeClass('show');
    }
  }

  function init() {
    if ($ && $.datepicker) {
      $.datepicker.regional[''].dateFormat = "dd/mm/yy"; // english UK
    }
    $('body').bind('click', closeChoice2Popup);
    $('body').bind('axel-network-error', networkErrorCb);
    $(document).bind('axel-editor-ready', 
      function (ev, host) { 
        $(host).find("span.sg-hint[rel='tooltip']")
          .tooltip({ html: false })
          .bind('hidden', function(ev) { ev.stopPropagation(); });  // stopPropagation prevents tooltip 'hidden' event to hide modal windows when in modals
      });
    $(document).bind('axel-editor-ready', 
      function (ev, host) { 
        $(host).find("span.sg-mandatory[rel='tooltip']")
          .tooltip({ html: false })
          .bind('hidden', function(ev) { ev.stopPropagation(); });  // stopPropagation prevents tooltip 'hidden' event to hide modal windows when in modals
      });
    if (typeof $axel !== 'undefined') {
      $axel.command.install(document); // deferred axel installation
      $axel.addLocale('en', {
        errLoadDocumentStatus : function (values) { 
          var msg = $axel.oppidum.parseError(values.xhr, undefined, undefined, values.url);
          if (values.xhr.status === 401) {
            msg = msg + "\n\n" + "This may be because your session has expired. In that case you need to reload the page and to identify again. If you are in the middle of an editing action, open a new window to identify yourself, this should allow you to save again in the first window. If this problem persists please check that your browser accepts cookies.";
          }
          return msg;
        }
      });
      $axel.setLocale('en');
    }
  }

  jQuery(function() { init(); });
}());
