(function () {

  // see http://stackoverflow.com/questions/13649459/twitter-bootstrap-multiple-modal-error
  // FIXME: upgrade to Bootstrap 3 ?
  var openmodals = [];
  function patchBootstrapModals() {
    var ts = new Date().getTime();
    $("div.modal").each(function( d ) {
      ts++;
      $( this ).data( "uid", ts );
    });

    // after closing > 1 level modals we want to reopen the previous level modal
    $('div.modal').on('show', function ( ev ) {
      if (! $(ev.target).hasClass('sg-hint')) { // guard
        openmodals.push({ 'id' : $( this ).data( "uid" ), 'el' : this });
        if( openmodals.length > 1 ){
          $( openmodals[ openmodals.length - 2 ].el ).modal('hide');
        }
      }
    });
    $('div.modal').on('hide', function ( ev ) {
      // no need of guard because app.js prevents closing events on tooltips
      if( openmodals.length > 1 ){
          if( openmodals[ openmodals.length - 1 ].id === $( this ).data( "uid" ) ){
              openmodals.pop(); // pop current modal
              $( openmodals.pop().el ).modal('show'); // pop previous modal and show, will be pushed on show
          }
      } else if( openmodals.length > 0 ){
          openmodals.pop(); // last modal closing, empty the stack
      }
    });
  }

  function hideSpinningWheel () {
    $('#c-busy').hide();
  }

  // FIXME: subscribe to 'axel-target-replaced' event (idem for sorting)
  function init() {
    $('#results').parent().click(showItemDetails);
    $('#c-modify-btn').click(editItem );
    $('#c-item-editor').bind('axel-save-done', itemSaveDone );
    $('#c-item-viewer').bind('axel-delete-done', itemDeleteDone );
    patchBootstrapModals();
    $('#editor').bind('axel-save-cancel', hideSpinningWheel).bind('axel-save-error', hideSpinningWheel);
    $('#editor').bind('axel-save-done',  // special tooltips in results list
      function (ev, host) {
        hideSpinningWheel();
        $('#results').find("a[rel='tooltip']").tooltip({ html: false });
        $('#results').find("span[rel='tooltip']").tooltip({ html: false });
      });
    $('#results').find("a[rel='tooltip']").tooltip({ html: false });
    $('#results').find("span[rel='tooltip']").tooltip({ html: false });
  }

  // Opens up modal window to display item details inside modal window
  function showItemDetails (ev) {
    var target = $(ev.target),
        src = target.attr('data-src'),
        ed;
    if (src) {
      // src = src + '.blend';
      if ('!' === src.charAt(0)) { // edit
        src = src.substr(1);
        $('#c-modify-btn').show();
      } else {
        $('#c-modify-btn').hide();
      }
      ed = $axel.command.getEditor('c-item-viewer');
      if ($axel('#c-item-viewer').transformed()) { // reuse
        ed.attr('data-src', src);
        $axel('#c-item-viewer').load(src);
        if ($axel('#c-item-viewer').transformed()) {
          $('#c-item-viewer-modal').modal('show');
        }
      } else { // first time
        ed.attr('data-src', src);
        ed.transform();
        if ($axel('#c-item-viewer').transformed()) {
          $('#c-item-viewer').bind('axel-cancel-edit', function() { $('#c-item-viewer-modal').modal('hide'); });
          $('#c-item-viewer-modal').modal('show');
        }
      }
    }
  }

  // Opens up modal window to edit item details inside modal window
  function editItem (ev) {
    var ed1 = $axel.command.getEditor('c-item-viewer'),
        ed2 = $axel.command.getEditor('c-item-editor'),
        src;
    if (ed1 && ed2) {
      // src = ed1.attr('data-src').replace(".blend",".xml?goal=update");
      src = ed1.attr('data-src') + "?goal=update";
      if (src) {
        if ($axel('#c-item-editor').transformed()) { // reuse
          ed2.reset();
          $('#c-item-editor .af-error').hide(); // see supergrid
          $('#c-item-editor-errors').removeClass('af-validation-failed');
          ed2.attr('data-src', src);
          $axel('#c-item-editor').load(src);
          if ($axel('#c-item-editor').transformed()) {
            $('#c-item-editor-modal').modal('show');
          }
        } else { // first time
          ed2.attr('data-src', src);
          ed2.transform();
          if ($axel('#c-item-editor').transformed()) {
            $('#c-item-editor').bind('axel-cancel-edit', function() { $('#c-item-editor-modal').modal('hide'); });
            $('#c-item-editor-modal').modal('show');
          }
        }
      }
    }
  }

  // Closes edit modal window and fakes an event to reload item details window content
  function itemSaveDone (ev, editor, source, xhr) {
    var src,
        ed1 = $axel.command.getEditor('c-item-viewer'),
        ed2 = $axel.command.getEditor('c-item-editor'),
        table;
    if (ed1 && ed2) {
      $('#c-item-editor-modal').modal('hide'); // should make display modal appear
      src = ed2.attr('data-src').replace('?goal=update',''); // refresh content
      ed1.attr('data-src', src);
      $axel('#c-item-viewer').load(src);
      // side effects on results table display
      table = $('Payload', xhr.responseXML).attr('Table');
      if (table === 'Enterprise') {
        reportEnterpriseUpdate(xhr.responseXML);
      } else { // Generic Ajax row update protocol
        updateRow(xhr);
      }
    }
  }

  // Closes view modal window and remove person from table
  function itemDeleteDone (ev, editor, source, xhr) {
    var id, table, jrowsel;
    $('#c-item-viewer-modal').modal('hide');
    // side effects on results table display
    table = $('Payload', xhr.responseXML).attr('Table');
    if ((table === 'Person') || (table === 'Enterprise') || (table === 'Region')) {
      id = $('Value', xhr.responseXML).text();
      jrowsel = "tr[data-id='" + id + "']";
      $(jrowsel + " td:first-child").html('<del>' + $(jrowsel + " a:first-child").text() + '</del>');
    }
  }

  // Updates a single result table row from the XHR responseXML returned when updating an Enterprise
  function reportEnterpriseUpdate(response) {
    updateEnterprise(
      $('Value', response).text(),
      $('Name', response).text(),
      $('Town', response).text(),
      $('RegionRef', response).text(),
      $('Size', response).text(),
      $('DomainActivity', response).text(),
      $('TargetedMarkets', response).text()
    );
  }

  // Updates the single result table row corresponding to an enterprise with data-id equal to id
  function updateEnterprise(id, name, town, region, size, domain, markets) {
    var row = $('tr[data-id="' + id + '"] > td');
    row.eq(0).children('a').children('span').text(name);
    row.eq(1).text(town);
    row.eq(2).text(region);
    row.eq(3).text(size);
    row.eq(4).text(domain);
    row.eq(5).text(markets);
  }

  // Updates a single result table row from the XHR responseXML returned when updating an Enterprise
  function updateRow(xhr) {
    var buffer = $axel.oppidum.unmarshalPayload(xhr),
        m = buffer.match(/data-id="(-?\d+)"/),
        dest, skip;
    if (m) {
      dest = $('tr[data-id="' + m[1] + '"]');
      skip = parseInt(dest.children('td[rowspan]').attr('rowspan'));
      if (!isNaN(skip)) {
        while (--skip > 0) {
          dest.next('tr').remove();
        }
      }
      dest.replaceWith(buffer);
    }
  }

  jQuery(function() { init(); });
}());
