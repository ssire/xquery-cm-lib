(function () {
  var _serializer; 
  
  function ajaxError(response, status, xhr) { 
    if (status === 'error') { $axel.error($axel.oppidum.parseError(xhr, status)) }
  }

  function dumpSchema() {
    var dump = new xtiger.util.SchemaLogger ();
    if (_serializer === undefined) {
      _serializer = new xtiger.editor.BasicSerializer ();
    }
    $axel('#x-simulator').xml ( { serializer : _serializer, logger : dump } );
    return "*** Schema generator output ***\n" + dump.dump('*');
  }

  // Opens a window with an iframe to display the current template source code
  // It uses the view-source: URL protocol with relative URLs, so currently it works
  // only with Firefox (chrome does not seem to like relative URLs)
  function viewTemplateSource (url) {
    var location, win, div, count = 0;
    location = "view-source:" + url;
    win = window.open(null, "Template source", 'width=800,height=800,location=no,toolbar=no,menubar=no');
    win.focus();
    // creates a document in popup window and default message for unsupported browsers
    win.document.open();
    win.document.write('To actually see the template source code in this window you must use a browser supporting the view-source protocol');
    win.document.close();
    win.document.title = "Source of '" + url + "'";
    div = win.document.createElement('div');
    div.innerHTML = '<iframe src="' + "javaScript:'To actually see the template source code in this window you must use a browser supporting the view-source protocol with relative URLs like Firefox'" + '" frameborder="0" style="width:100%;height:100%"><iframe>';
    win.document.body.replaceChild( div, win.document.body.firstChild );
    win.document.body.style.margin = "0";
    win.onload = function() {
      var doc = win.frames[0].document;
      $('pre', doc).css('white-space', 'pre-wrap'); // trick to wrap lines (Firefox)
    };
    // actually instructs to view template source
    // bind to load event to force a reload to avoid caching issue !
    $('iframe', div).bind('load', function () { if (!count++) { this.contentWindow.location.reload(true);} }).attr('src',location);
  }

  // pre-condition: data-bundles-path set on axel script element (see skin.xml)
  function init() {
    var bundles = /static\/.*/.exec($('script[data-bundles-path]').attr('data-bundles-path'))[0];
    $axel.setup({ bundlesPath : bundles, tabGroupNavigation: true });
    $('#x-model').bind('click', function() { viewTemplateSource($('#x-formular').val() + '?goal=model'); });
    $('#x-generate').bind('click', function() { viewTemplateSource($('#x-formular').val() + '?goal=save'); });
    $('#x-src').bind('click', function() { viewTemplateSource($('#x-formular').val() + '.xml'); });
    $('#x-test').bind('click', function() { 
      var target = $('#x-simulator').get(0);
      $axel('#x-simulator').transform($('#x-formular').val() + '?goal=test'); 
      $('#c-editor-errors').removeClass('af-validation-failed'); 
      $axel.command.install(document, target);
      $axel.binding.install(document, target);
      });
    $('#x-control').bind('click', function() { $axel('#x-simulator').transform($('#x-formular').val() + '?goal=save'); });
    $('#x-dump').bind('click', function() { alert($axel('#x-simulator').xml()); });
    $('#x-schema').bind('click', function() { alert(dumpSchema()); });
    $('#x-mesh').bind('click', 
      function(ev) { 
        var curval = $('#x-formular').val(),
            module = $(ev.target).attr('data-base-url').match(/\/([^\/]*)?\/$/)[1],
            tplurl = curval.replace('forms/', 'mesh/') + '.xhtml';
        window.location.href = '/exist/rest/db/www/' + module + '/' + tplurl;
      });
    $('#x-extensions').bind('click', 
      function() { 
        var target = $('#x-simulator').get(0),
            curval = $('#x-formular').val(),
            tplurl = ($('#x-formular option[value="' + curval +'"]').attr('data-display') || curval.replace('forms/', 'templates/')) + '.xml?goal=' + $('#x-mode').val();
        window.location.href = tplurl;
      });
    $('#x-display').bind('click', function() { 
      var target = $('#x-simulator').get(0),
          curval = $('#x-formular').val(),
          tplurl = ($('#x-formular option[value="' + curval +'"]').attr('data-display') || curval.replace('forms/', 'templates/')) + '?goal=' + $('#x-mode').val();
      // $('body xt\\:use', t).attr('types','t_simulation')
      $axel('#x-simulator').transform(tplurl); 
      $('#c-editor-errors').removeClass('af-validation-failed'); 
      $axel.command.install(document, target);
      $axel.binding.install(document, target); 
      });
    $('#x-validate').bind('click', function() { $axel.binding.validate($axel('#x-simulator'), 'c-editor-errors', document, 'label', '.hide') });
    $('#x-install').bind('click', 
      function() { $('#x-simulator').load(
        'forms/install?gen=' + $('#x-formular').val().replace('forms/',''),
        ajaxError)
      });
    $('#x-install-all').bind('click', function() { $('#x-simulator').load('forms/install?gen=' + encodeURIComponent($('#x-formular option').map(function(i,e) { return $(e).val().replace('forms/','') }).toArray().join('+'))); });
  }
  
  jQuery(function() { init(); });
}());
