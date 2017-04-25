(function () {

  function init() {
    $('.nav-tabs a').click(function (e) {
        var jnode = $(this),
            pane= $(jnode.attr('href')),
            url = jnode.attr('data-src');
        pane.html('<p id="c-busy" style="height:32px"><span style="margin-left: 48px">Loading in progress...</span></p>');
        jnode.tab('show');
        pane.load(url, function(txt, status, xhr) {
          if (status !== "success") { pane.html('Impossible to load the page, maybe your session has expired, please reload the page to login again'); }
          if ($.tablesorter) {
	    $('[name*="users"]').tablesorter({ textExtraction: function(node) {
	      var n = node.getElementsByTagName('a');
	        if (n.length === 0) {
	          n = node.getElementsByTagName('span');
	        }
		if (n.length > 0) {
		  return n[0].textContent;
		} else {
		  return node.textContent;
		}
              }
	    });
            // clicking on input within table cell triggers tablesort without getting focus on 
            // inserted input so clicking on input shall put focus and does not fire tablesorter
            $('[name*="users"]').find('input').each(function(i,e) {
              $(e).first().click(function( event ) {
                $(this).focus()
                event.stopPropagation();
              });
            })
	  }  
          $('#results-export').children('a').first().click(function() {
            return ExcellentExport.severalExcel(this, document.getElementsByName('users'), "Users");
          });
          $('#results-export').children('a').eq(1).click(function() {
            return ExcellentExport.csv(this, $('[name="users"]').get(0), ",");
          });
          $('#results-export').children('a').eq(2).click(function() {
            $('#user-filter').val('')
            $('#country-filter').val('')
            $('#role-filter').val('')
            $('#user-filter').keyup();
            return ;
          });
        });
    });

    $('a[data-toggle="tab"]').on('show', function (e) {
        var jnode = $(e.target),
            pane= $(jnode.attr('href')),
            url = jnode.attr('data-src');
        if (url.charAt(0) !== '#') {
          pane.load(url, function(txt, status, xhr) { if (status !== "success") { pane.html('Impossible to load the page'); }  });
        }
    });    
    // person editing modal
    $('#c-pane-users').parent().click(showItemDetails);
    $('#c-pane-users').bind('keyup', filterUsers);
    $('#c-pane-remotes').bind('keyup', filterUsers);
    // thesaurus editing modal
    $('#c-pane-thesaurus').parent().click(openThesaurusEditor);
    $('#c-thesaurus-editor').bind('axel-cancel-edit', function() { $('#c-thesaurus-editor-modal').modal('hide'); });
    $('#c-thesaurus-editor').bind('axel-save-done', function() { $('#c-thesaurus-editor-modal').modal('hide'); });        
    // params editing modal
    $('#c-pane-params').bind('coaching-update-params', openParamsEditor);
    $('#c-params-editor').bind('axel-cancel-edit', function() { $('#c-params-editor-modal').modal('hide'); });
    $('#c-params-editor').bind('axel-save-done', function() {
      $('#c-params-editor-modal').modal('hide');
      $('a[href="#c-pane-params"]').click(); // reloads pane content
      });
  }

  // Opens up modal window, loads it pre-defined template, loads target data inside it
  function openThesaurusEditor (ev) {
    var target = $(ev.target),
        src, key, wrapper, ed, 
        goal = 'update';
    src = target.attr('data-controller');
    if (src) {
      wrapper = $axel('#c-thesaurus-editor');
      ed = $axel.command.getEditor('c-thesaurus-editor');
      ed.attr('data-src', null); // a. remove any potential data source previously set in b
      ed.ready = false; // forces template reload and transformation FIXME: change API
      ed.transform(src);
      if (wrapper.transformed()) {
        ed.attr('data-src', src); // b. sets same URL as template as data source for 'save' command
        $('#c-thesaurus-editor-modal').modal('show');
      }
    }
  }

  // Opens up modal window, loads it pre-defined template, loads target data inside it
  function openParamsEditor (ev) {
    var src, wrapper, ed;
    wrapper = $axel('#c-params-editor');
    ed = $axel.command.getEditor('c-params-editor');
    ed.attr('data-src', null); // a. remove any potential data source previously set in b
    ed.ready = false; // forces template reload and transformation FIXME: change API
    ed.transform();
    if (wrapper.transformed()) {
      ed.attr('data-src', 'management/params'); // b. sets same URL as template as data source for 'save' command
      $('#c-params-editor-modal').modal('show');
    }
  }

  // Opens up modal window, loads it pre-defined template, loads target data inside it
  function showItemDetails (ev) {
    var target = $(ev.target),
        src, key, wrapper, ed, 
        goal = 'update';
    // 1. find data source and key to identify target editor
    src = (target.hasClass('fn') ? target.parent().attr('data-person') : target.attr('data-person'));
    if (src) {
      key = 'person';
    } else {
      src = target.attr('data-remote');
      if (src) {
        key = 'remote';
      }
      else {
        src = target.attr('data-profile');
        if (src) {
          key = 'profile';
        } else {
          src = target.attr('data-login');
          if (src) {
            key = 'login';
          } else {
            src = target.attr('data-nologin');
            if (src) {
              key = 'nologin';
              goal = 'create';
            } else {
              src = target.attr('data-noremote');
              if (src) {
                key = 'noremote';
                goal = 'create';
              }
            }
          }
        }
      }
    }
    // 2. transform editor, load data, show modal
    if (src) {
      wrapper = $axel('#c-' + key + '-editor');
      src = src + ".xml?goal=" + goal;
      ed = $axel.command.getEditor('c-' + key + '-editor');
      if (wrapper.transformed()) { // reuse
        wrapper.load('<Reset/>'); // FIXME: ed.empty() ?
        $('#c-' + key + '-editor .af-error').hide();
        $('#c-' + key + '-editor-errors').removeClass('af-validation-failed');
        ed.attr('data-src', src);
        wrapper.load(src);
        if (wrapper.transformed()) {
          $('#c-' + key + '-editor-modal').modal('show');
        }
      } else { // first time
        ed.attr('data-src', src);
        ed.transform();
        if (wrapper.transformed()) {
          $('#c-'+ key + '-editor').bind('axel-cancel-edit', function() { $('#c-' + key + '-editor-modal').modal('hide'); });
          $('#c-' + key + '-editor-modal').modal('show');
        }
        $('#c-' + key + '-editor').bind('axel-save-done', itemSaveDone );
        $('#c-' + key + '-editor').bind('axel-delete-done', itemDeleteDone);
      }
    } 
  }
  
  function filterName ( e, str ) {
    return (e.textContent.toUpperCase().indexOf(str) == -1) && (e.nextSibling && (e.nextSibling.textContent.toUpperCase().indexOf(str) == -1));
  }

  // Filters users table rows
  function filterUsers (ev) {
    var t = $(ev.target);
    var tab = $('div[class="tab-pane active"]').attr('id')

    if (t.attr('id') === 'user-filter' || t.attr('id') === 'key-filter' || t.attr('id') === 'country-filter' || t.attr('id') === 'role-filter') {
      var uf = (tab == 'c-pane-users' ? $('#user-filter') : $('#key-filter')).val().toUpperCase() 

      $("span.fn").each( function (i,e) { 
        if (filterName(e, uf) || (tab == 'c-pane-users' && !checkCountryFilter(e)) || !checkRoleFilter(e)) {
          $(e).parents('tr').hide() 
        }
        else $(e).parents('tr').show()
      });
    }
  }
  
  function checkCountryFilter(e) {
    var cn = $(e).parents('tr').find('span.cn')
    var cf = $('#country-filter').val().toUpperCase()

    if (cf == '' || cn.html() == null) return true; // void search field or no country assigned to the user

    return cn.html().toUpperCase().indexOf(cf) !== -1;
  }
  
  function checkRoleFilter(e) {
    var rn = $(e).parents('tr').find('span.rn')
    var rf = $('#role-filter').val().toUpperCase()

    if (rf == '' || rn.html() == null) return true; // void search field or no role assigned to the user

    var arr = $(rn).html().split(','), incl = 0;

    for (i = 0; i < arr.length; i++) {
      if (arr[i].toUpperCase().indexOf(rf) !== -1) // search substring
        incl = 1;
    }

    return incl || arr.length == 0;
  }
  
  // Closes edit modal window and fakes an event to reload item details window content
  function itemSaveDone (ev, editor, source, xhr) {
    var key; console.log('itemsavedone')
    key = $('Payload', xhr.responseXML).attr('Key') || $('Payload', xhr.responseXML).attr('Table'); // two procotols
    if ((key === 'Person') || ($('Person', xhr.responseXML).attr('Update') === 'y')) {
      key = 'person'; // trick to share person controller with search.js
    }
    $('#c-' + key + '-editor-modal').modal('hide'); // should make display modal appear
    if (key === 'login') {
      reportLoginUpdate(xhr.responseXML);
    } else if (key === 'nologin') {
      reportLoginCreation(xhr.responseXML);
    } else if (key === 'person') {
      reportPersonUpdate(xhr.responseXML);
    } else if (key === 'remote') {
      reportRemoteUpdate(xhr.responseXML);
    } else if (key === 'profile') {
      reportProfileUpdate(xhr.responseXML);
    }
  }

  function reportLoginUpdate(response) {
    var id = $('Value', response).text(),
        label = $('Name', response).text();
    $("a[data-login$='/" + id + "']").text(label);
  }
  
  function reportLoginCreation(response) {
    var id = $('Value', response).text(),
        label = $('Name', response).text(),
        jnode = $("a[data-nologin$='/" + id + "']");
    jnode.parent().prev('td').html('<a data-login="' + jnode.attr('data-nologin')  +  '">' + label + '</a>');
    jnode.parent().html('oui');
  }

  // TODO: improve protocol, quick and dirty decoding because .xml suffix shortcuts 
  // a full html table row response shared with the controller of search.js
  function reportPersonUpdate(response) {
    var id = $('Id', response).text(),
        fn = $('LastName', response).text(),
        first = $('FirstName', response).text(),
        email = $('Email', response).text() || '',
        country = $('Country', response).text() || '',
        jnode = $('a[data-person$="/' + id + '"]').parents('tr');
        
    $('a[data-person$="/' + id + '"]').html('<span class="fn">' + fn + '</span> ' + first);
    jnode.children('td:eq(1)').text(email);
    jnode.children('td:eq(2)').html('<span class="cn">' + country + '</span>');
  }

  function reportProfileUpdate(response) {
    var id = $('Value', response).text(),
        label = $('Name', response).text();
    $("span[data-profile$='/" + id + "']").text(label);
  }

  function reportRemoteUpdate(response) {
    var id = encodeURIComponent($('Value', response).text()).replace(/\./g, "%2E"),
        label = $('Name', response).text(),
        contact = $('Contact', response).text()
    $("span[data-remote$='/" + id + "']").parents('tr').children('td:eq(0)').text(contact)
    $('span[data-remote$=' + '"' + id + '"]').text(label).attr('data-remote', 'profiles/' + encodeURIComponent(contact).replace(/\./g, "%2E"));
  }

  function itemDeleteDone (ev, editor, source, xhr) {
    var key, id, jnode;
    key = $('Payload', xhr.responseXML).attr('Key') || $('Payload', xhr.responseXML).attr('Table');
    if (key === 'Person') {
      key = 'person'; // trick to share person controller with search.js
    }
    $('#c-' + key + '-editor-modal').modal('hide'); // should make display modal appear
    if (key === 'person') {
      id = $('Value', xhr.responseXML).text();
      jnode = $('a[data-person$="/' + id + '"]').parents('tr').children('td').html('---');
    } else if (key === 'login') {
      id = $('Value', xhr.responseXML).text();
      jnode = $('a[data-login$="/' + id + '"]');
      jnode.parents('tr').children('td:eq(5)').html('<a data-nologin="accounts/' + id  + '">create</a>');
      jnode.parent().html('---');
    }
  }
  
  /*****************************************************************************\
  |                                                                             |
  |  'c-password' command object                                                |
  |                                                                             |
  \*****************************************************************************/
  (function () {
    function PasswordCommand ( identifier, node ) {
      this.spec = $(node);
      this.spec.bind('click', $.proxy(this, 'execute'));
    }
    PasswordCommand.prototype = {
      
      // FIXME: manage server side error messages (and use 200 status)
      successCb : function (response, status, xhr) {
        alert($('success > message', xhr.responseXML).text());
        this.spec.triggerHandler('axel-transaction-complete', { command : this });
        var target = this.spec.attr('data-target');
        $('#' + target + '-modal').modal('hide'); // hides modal window (convention)
      },
      
      errorCb : function (xhr, status, e) {
        this.spec.trigger('axel-network-error', { xhr : xhr, status : status, e : e });
        this.spec.triggerHandler('axel-transaction-complete', { command : this });
      },
      
      execute : function () {
        var target = this.spec.attr('data-target'),
            ed, ctrl;
        if (target) { // attached to an editor 
          ed = $axel.command.getEditor(target);
          if (ed) {
            ctrl = ed.attr('data-src');
            if (ctrl) {
              if (/\.[\w\?=]*$/.test(ctrl)) {   // replaces end of URL with '/delete' (eg: .blend or .xml?goal=update)
                ctrl = ctrl.replace(/\.[\w\?=]*$/, '?regenerate=1');
              } else {
                ctrl = ctrl + '?regenerate=1';
              }
            }
          }
        }
        if (ctrl) {
          this.spec.triggerHandler('axel-transaction', { command : this });
          $.ajax({
            url : ctrl,
            type : 'post',
            cache : false,
            timeout : 20000,
            success : $.proxy(this, "successCb"),
            error : $.proxy(this, "errorCb")
          });
        } else {
          alert('Information manquante, signalez-nous le problème !');
        }
      }
    };
    $axel.command.register('c-password', PasswordCommand, { check : false });
  }());  
  
  jQuery(function() { init(); });
}());
