(function () {

  /*****************************************************************************\
  |                                                                             |
  |  'header' command object                                                    |
  |                                                                             |
  |  To be set on a thead in a table. Subscribes to its editor and removes      |
  |  any c-empty potential class on the command's table parent each time        |
  |  the editor emits 'axel-save-done' event. Subscribes to a second optional   |
  |  target data-event-target if provided.                                      |
  |                                                                             |
  \*****************************************************************************/
  (function () {
    function HeaderCommand ( identifier, node ) {
      var tmp;
      this.spec = $(node);
      $('#' + identifier).bind('axel-save-done', $.proxy(this, 'execute'));
      tmp = this.spec.attr('data-event-target');
      if (tmp) {
        $('#' + tmp).bind('axel-save-done', $.proxy(this, 'execute'));
      }
    }
    HeaderCommand.prototype = {
      execute : function () {
        var counter = this.spec.attr('data-counter'),
            n;
        this.spec.parent().removeClass('c-empty').next('.c-empty').remove();
        if (counter) {
          n = $('#' + counter);
          n.text(n.text().replace(/\d+/, this.spec.parent().children('tbody').children('tr').size()));
        }
      }
    };
    $axel.command.register('header', HeaderCommand, { check : false });
  }());

  /*****************************************************************************\
  |                                                                             |
  |  'status' command object                                                    |
  |                                                                             |
  |  Manages ChangeStatus action                                                |
  |                                                                             |
  \*****************************************************************************/
  (function () {
    function ChangeStatusCommand ( identifier, node ) {
      this.spec = $(node);
      this.key = identifier;
      this.spec.bind('click', $.proxy(this, 'execute'));
      $('#' + this.key).bind('axel-cancel-edit', $.proxy(this, 'cancel'));
      $('#' + this.spec.attr('data-target-modal')).on('hidden', $.proxy(this, 'cancel'));
      // $('#' + this.key).bind('axel-save-done', $.proxy(this, 'saved')); redirection done per-save protocol
    }
    ChangeStatusCommand.prototype = {
      execute : function (event) {
        var model = $(event.target),
            warn= this.spec.attr('data-confirm'),
            action = model.attr('data-action'),
            argument = model.attr('data-argument') || 1;
        if (action) {
          if (warn && confirm(warn)) {
            this.spec.triggerHandler('axel-transaction', { command : this });
            $.ajax({
              url : this.spec.attr('data-status-ctrl'),
              type : 'post',
              data : { action : action, argument : argument, from : this.spec.attr('data-status-from') },
              dataType : 'xml',
              success : $.proxy(this, 'successCb'),
              error : $.proxy(this, 'errorCb'),
              async : false
            });
          }
        } else if (! model.attr('data-command')) { // squatted by another command
          alert('Wrong configuration in menu');
        }
      },
      // status updated successfully
      successCb : function  ( response, status, xhr ) {
        var ed = $axel.command.getEditor(this.key),
            cmd = $axel.oppidum.getCommand(xhr);
        this.redirect = xhr.getResponseHeader('Location');
        if ($('success > done', cmd.doc).size() > 0) { // <done/> protocol to shortcut e-mail modal window
          this.cancel();
        } else {
          $('#' + this.spec.attr('data-target-modal')).modal('show');
          if (this.spec.attr('data-init')) { // optional initialization
            ed.attr('data-src', this.spec.attr('data-init'));
          } else {
            ed.attr('data-src', ''); // to prevent XML data loading
          }
          ed.transform(this.spec.attr('data-with-template'));
          if ($axel('#' + this.key).transformed()) { // assumes synchronous transform()
            ed.attr('data-src', this.spec.attr('data-src')); // since its synchronous it will not trigger XML data loading
          }
        }
      },
      // status not updated
      errorCb : function ( xhr, status, e ) {
        this.spec.trigger('axel-network-error', { xhr : xhr, status : status, e : e });
        this.spec.triggerHandler('axel-transaction-complete', { command : this });
      },
      // continue w/o sending alert message
      cancel : function (event) {
        this.spec.triggerHandler('axel-transaction-complete', { command : this });
        window.location.href = this.redirect;
      }
    };
    $axel.command.register('status', ChangeStatusCommand, { check : true });
  }());

  /*****************************************************************************\
  |                                                                             |
  |  'acc-drawer' command object                                                |
  |                                                                             |
  |  Tracks drawer button to open / close drawer for drawers inside accordions  |
  |  MUST be placed on the drawer div that contains the drawer editor           |
  |                                                                             |
  \*****************************************************************************/
  (function () {
    function DrawerCommand ( identifier, node ) {
      this.spec = $(node);
      this.key = identifier;
      $('#' + this.spec.attr('data-drawer-trigger')).bind('click', $.proxy(this, 'execute'));
      $('#' + this.key).bind('axel-cancel-edit', $.proxy(this, 'cancel'));
      $('#' + this.key).bind('axel-save-done', $.proxy(this, 'saved'));
    }
    DrawerCommand.prototype = {
      execute : function () {
        this.spec.collapse('show');
      },
      cancel : function (event) {
        this.spec.collapse('hide').children('.af-validation-failed').removeClass('af-validation-failed');
      },
      saved : function (event) {
        this.spec.collapse('hide');
      }
    };
    $axel.command.register('acc-drawer', DrawerCommand, { check : true });
  }());

  /*****************************************************************************\
  |                                                                             |
  |  'drawer' command object                                                    |
  |                                                                             |
  |  Tracks drawer button to open / close drawer                                |
  |  MUST be placed on the drawer's accordion '.accordion-group' div            |
  |                                                                             |
  \*****************************************************************************/
  (function () {
    function DrawerCommand ( identifier, node ) {
      this.spec = $(node);
      this.key = identifier;
      this.spec.children('.accordion-heading').children('.c-document-menu').children('button').bind('click', $.proxy(this, 'execute'));
      $('#' + this.key).bind('axel-cancel-edit', $.proxy(this, 'cancel'));
      $('#' + this.key).bind('axel-save-done', $.proxy(this, 'saved'));
    }
    DrawerCommand.prototype = {
      execute : function () {
        this.spec.children('.accordion-body').collapse('show');
        this.spec.addClass('c-opened');
      },
      cancel : function (event) {
        this.spec.children('.accordion-body').collapse('hide');
        this.spec.removeClass('c-opened');
        // as next 'edit' action will reset() the editor we remove any potential editor's validation error pane
        this.spec.children('.accordion-body').children('.accordion-inner').children('.af-validation-failed').removeClass('af-validation-failed');
      },
      saved : function (event) {
        this.spec.children('.accordion-body').collapse('hide');
        this.spec.removeClass('c-opened');
      }
    };
    $axel.command.register('drawer', DrawerCommand, { check : true });
  }());

  /*****************************************************************************\
  |                                                                             |
  |  'view' command object                                                      |
  |                                                                             |
  |  Loads a template inside a target editor and loads an XML resource into it  |
  |  Keeps monitoring the editor and reloads it on 'axel-cancel-edit' and on    |
  |  'axel-save-done' event.                                                    |
  |  MUST be placed on the drawer's accordion '.accordion-group' div            |
  |                                                                             |
  |*****************************************************************************|
  |                                                                             |
  |  Required attributes :                                                      |
  |  - data-target : id of the editor to control                                |
  |  - data-with-template : template URL                                        |
  |  - data-src : XML resource URL                                              |
  |                                                                             |
  \*****************************************************************************/
  (function () {
    function ViewCommand ( identifier, node ) {
      this.spec = $(node);
      this.key = identifier;
      // this.spec.bind('click', $.proxy(this, 'execute'));
      this.viewing = false;
      this.listening = false;
      node.axelCommand = this;
    }
    ViewCommand.prototype = {
      _dismiss : function (event) {
        // $('#' + this.key).unbind('axel-cancel-edit', $.proxy(this, 'cancel'));
        // $('#' + this.key).unbind('axel-save-done', $.proxy(this, 'saved'));
        // $('#' + this.key).unbind('axel-editor-ready', $.proxy(this, 'stolen'));
        // this.spec.get(0).disabled = false;
        $('#' + this.key).removeClass('c-display-mode').closest('.accordion-inner').addClass('c-editing-mode');
        this.viewing = false;
      },
      execute : function () {
        var ed;
        if (! this.viewing) {
          $('#' + this.spec.attr('data-target-ui')).add('#' + this.spec.attr('data-target-ui') + '-bottom').hide();
          ed = $axel.command.getEditor(this.key);
          ed.attr('data-src', this.spec.attr('data-src'));
          ed.transform(this.spec.attr('data-with-template'));
          if ($axel('#' + this.key).transformed() && !this.viewing) { // assumes synchronous transform()
            this.viewing = true;
            // this.spec.get(0).disabled = true;
            if (! this.listening) {
              $('#' + this.key).bind('axel-cancel-edit', $.proxy(this, 'cancel'))
                .bind('axel-save-done', $.proxy(this, 'saved'))
                .bind('axel-editor-ready', $.proxy(this, 'stolen'));
              this.listening = true;
            }
          }
          // The transformation above will trigger the stolen callback...
          $('#' + this.key).addClass('c-display-mode').closest('.accordion-inner').removeClass('c-editing-mode');
        }
      },
      // as 'view' command cannot be cancelled this comes from the other command sharing the editor (aka 'edit')
      cancel : function (event) {
        this.execute();
        // as next 'edit' action will reset() the editor we remove any potential editor's validation error pane
        this.spec.children('.accordion-body').children('.accordion-inner').children('.af-validation-failed').removeClass('af-validation-failed');
        // FIXME: merge 'view' and 'edit' command into a 'swap' command to avoid reloading data/editor ?
      },
      // as 'view' command cannot be cancelled this comes from the other command sharing the editor (aka 'edit')
      saved : function (event, editor, source) {
        var ed = $axel.command.getEditor(this.key);
        if (this.viewing && source && (ed !== source)) {
          // called from an editor embedded inside the target editor
          ed.reload();
        } else {
          this.execute();
        }
      },
      // some other document editor loaded
      stolen : function (event) {
        this._dismiss();
      }
    };
    $axel.command.register('view', ViewCommand, { check : true });
  }());

  /*****************************************************************************\
  |                                                                             |
  |  'edit' command object                                                      |
  |                                                                             |
  |*****************************************************************************|
  |                                                                             |
  |  Attributes :                                                               |
  |  - data-target : id of the editor where to send the event                   |
  |  - data-edit-action (optional) : set it to 'update' to edit existing data   |
  |    instead of editing new data                                              |
  |                                                                             |
  \*****************************************************************************/
  (function () {
    function EditCommand ( identifier, node ) {
      this.spec = $(node);
      this.key = identifier;
      this.spec.bind('click', $.proxy(this, 'execute'));
      this.editing = false;
    }
    EditCommand.prototype = {
      _enableCommands : function () {
        var tmp = this.spec.attr('data-command-ui');
        if (tmp === 'disable') {
          tmp = this.spec.closest('.c-document-menu');
          tmp.find('a.dropdown-toggle').removeClass('disabled');
          tmp.children('button').each(function(i,e) { e.disabled = false; });
        } else if (tmp === 'hide') {
          this.spec.closest('.c-document-menu').removeClass('c-hidden');
        } else {
          this.spec.get(0).disabled = false;
        }
      },
      _disableCommands : function () {
        var tmp = this.spec.attr('data-command-ui');
        if (tmp === 'disable') {
          tmp = this.spec.closest('.c-document-menu');
          tmp.find('a.dropdown-toggle').addClass('disabled');
          tmp.children('button').each(function(i,e) { e.disabled = true; });
        } else if (tmp === 'hide') {
          this.spec.closest('.c-document-menu').addClass('c-hidden');
        } else {
          this.spec.get(0).disabled = true;
        }
      },
      _dismiss : function (event) {
        $('#' + this.key).unbind('axel-cancel-edit', $.proxy(this, 'cancel'));
        $('#' + this.key).unbind('axel-save-done', $.proxy(this, 'saved'));
        $('#' + this.key).unbind('axel-editor-ready', $.proxy(this, 'stolen'));
        this._enableCommands(this.spec);
        $('#' + this.spec.attr('data-target-ui')).add('#' + this.spec.attr('data-target-ui') + '-bottom').hide();
        this.editing = false;
        // FIXME: close drawer if drawer mode
      },
      execute : function (event) {
        var ed = $axel.command.getEditor(this.key), tmp, validate = false;
        if (this.spec.attr('data-edit-action') === 'update') {
          ed.attr('data-src', this.spec.attr('data-src')); // preload XML data
          validate = true;
        } else if (this.spec.attr('data-init')) {
          ed.attr('data-src', this.spec.attr('data-init')); // preload XML data
        } else {
          ed.attr('data-src', ''); // to prevent XML data loading
        }
        this._disableCommands();
        ed.transform(this.spec.attr('data-with-template'));
        if ($axel('#' + this.key).transformed() && !this.editing) { // assumes synchronous transform()
          this.editing = true;
          ed.attr('data-src', this.spec.attr('data-src')); // since its synchronous it will not trigger XML data loading
          $('#' + this.key).bind('axel-cancel-edit', $.proxy(this, 'cancel'));
          $('#' + this.key).bind('axel-save-done', $.proxy(this, 'saved'));
          $('#' + this.key).bind('axel-editor-ready', $.proxy(this, 'stolen'));
          $('#' + this.spec.attr('data-target-ui')).add('#' + this.spec.attr('data-target-ui') + '-bottom').show();
          if (validate) { // pre-validation
            $axel.binding.validate($axel('#' + this.key), 
              undefined, // no concatenated display
              ed.doc, ed.attr('data-validation-label'));
          }
          // FIXME: display drawer if drawer mode
        } else {
          this._enableCommands();
        }
      },
      // as 'view' command cannot be cancelled (the other one sharing the same editor) this is from this 'edit' command
      cancel : function (event) {
        this._dismiss();
      },
      // as 'view' command cannot be cancelled (the other one sharing the same editor) this is from this 'edit' command
      saved : function (event) {
        this._dismiss();
      },
      // some other document editor loaded
      stolen : function (event) {
        this._dismiss();
      }
    };
    $axel.command.register('edit', EditCommand, { check : true });
  }());

  /*****************************************************************************\
  |                                                                             |
  |  'annex' command object                                                       |
  |                                                                             |
  |*****************************************************************************|
  |                                                                             |
  |  Required attributes :                                                      |
  |  - data-target : id of the editor where to send the event                   |
  |                                                                             |
  \*****************************************************************************/
  (function () {
    function AnnexCommand ( identifier, node ) {
      this.spec = $(node);
      this.key = identifier;
      this.spec.bind('click', $.proxy(this, 'execute'));
      this.listening = false;
    }
    AnnexCommand.prototype = {
      dismiss : function ( event ) {
        this.spec.get(0).disabled = false;
        // $('#' + this.spec.attr('data-target-modal')).modal('hide');
      },
      execute : function ( event ) {
        var ed = $axel.command.getEditor(this.key);
        ed.attr('data-src', ''); // to prevent XML data loading
        ed.transform(this.spec.attr('data-with-template'));
        if ($axel('#' + this.key).transformed()) { // assumes synchronous transform()
          this.spec.get(0).disabled = true;
          ed.attr('data-src', this.spec.attr('data-src')); // since its synchronous it will not trigger XML data loading
          if (! this.listening) {
            $('#' + this.key).bind('axel-cancel-edit', $.proxy(this, 'dismiss'));
            $('#' + this.key).bind('axel-update', $.proxy(this, 'updated'));
            // $('#' + this.spec.attr('data-target-modal')).on('hidden', $.proxy(this, 'dismiss'));
            this.listening = true;
          }
          // $('#' + this.spec.attr('data-target-modal')).modal('show');
        }
      },
      // 'file' upload plugin event with response payload extracted into event.value
      updated : function (event ) {
        var list = $('#' + this.spec.attr('data-append-target'));
        $('#c-no-annex').hide();
        list.parent().removeClass('c-empty'); // show table (can't use 'header' command since no 'axel-save-done' event with 'file' plugin)
        list.prepend(event.value);
      }
    };
    $axel.command.register('annex', AnnexCommand, { check : true });
  }());

  /*****************************************************************************\
  |                                                                             |
  |  'c-delannexe' command object                                               |
  |                                                                             |
  |   Special command to delete annexes in a list                               |
  |                                                                             |
  \*****************************************************************************/
  (function () {
    function DeleteCommand ( identifier, node ) {
      this.spec = $(node);
      this.spec.bind('click', $.proxy(this, 'execute'));
    }
    DeleteCommand.prototype = {

      successCb : function (response, status, xhr) {
        var l = this.anchor.text();
        if (xhr.status === 200) { // end of transactional protocol
          alert($('success > message', xhr.responseXML).text());
          this.anchor.parent().html('<del>' + l + '</del>');
          this.trash.remove();
        } else {
          this.spec.trigger('axel-network-error', { xhr : xhr, status : "unexpected" });
        }
      },

      errorCb : function (xhr, status, e) {
        this.spec.trigger('axel-network-error', { xhr : xhr, status : status, e : e });
      },

      execute : function (ev) {
        var ask = this.spec.attr('data-confirm'),
            t = $(ev.target),
            m, url;
        if (t.attr('data-file')) {
          this.trash = t;
          this.anchor = t.parent().prev('td').prev('td').children('a').first();
          url = this.anchor.attr('href');
          if (ask) {
            proceed = confirm(ask.replace('%s', t.attr('data-file')));
            m = 'post'; // 'delete';
          }
          if (proceed && url) {
            $.ajax({
              url : url,
              type : m,
              data : { '_delete' : 1 },
              cache : false,
              timeout : 20000,
              success : $.proxy(this, "successCb"),
              error : $.proxy(this, "errorCb")
            });
          }
        }
      }
    };
    $axel.command.register('c-delannexe', DeleteCommand, { check : false });
  }());
  
  /*****************************************************************************\
  |                                                                             |
  |  'confirm' command object                                                   |
  |                                                                             |
  |  Subset of the 'save' command protocol that just implements a two-steps     |
  |  confirmation protocol to generate whatever side effect server side         |
  |                                                                             |
  \*****************************************************************************/
  (function () {

    function ConfirmCommand ( identifier, node, doc ) {
      this.spec = $(node);
      this.key = identifier;
      this.spec.bind('click', $.proxy(this, 'execute'));
    }

    ConfirmCommand.prototype = (function () {

      function confirmSuccessCb (response, status, xhr, memo) {
        var loc, tmp, proceed;
        // 1st part of protocol : confirmation dialog
        if ((xhr.status === 202) && memo) { 
          proceed = confirm($('success > message', xhr.responseXML).text());
          if (memo.url.indexOf('?') !== -1) {
            tmp = memo.url + '&_confirmed=1';
          } else {
            tmp = memo.url + '?_confirmed=1';
          }
          if (proceed) {
            $.ajax({
              url : tmp,
              type : memo.method,
              cache : false,
              timeout : 50000,
              success : $.proxy(confirmSuccessCb, this),
              error : $.proxy(confirmErrorCb, this)
            });
            return; // short-circuit final call to finished
          }
        // 2nd part of protocol : optional redirection
        } else if ((xhr.status === 201) || (xhr.status === 200)) {
          loc = xhr.getResponseHeader('Location');
          if (loc) {
            window.location.href = loc;
          }
        } else { // FIXME: use AXEL localizable error ?
          $axel.error('Unexpected response from server (' + xhr.status + '). Command may have failed');
        }
        this.spec.removeAttr('disabled');
      }

      function confirmErrorCb (xhr, status, e) {
        if (xhr.status === 409) {
          alert($('error > message', xhr.responseXML).text());
        } else {
          this.spec.trigger('axel-network-error', { xhr : xhr, status : status, e : e });
        }
        this.spec.removeAttr('disabled');
      }

      return {
        execute : function (event) {
          var method, _successCb, _memo, 
             _this = this,
             url = this.spec.attr('data-src') || editor.attr('data-src') || '.';
          if (url) {
            method = this.spec.attr('data-method') || 'post';
            url = $axel.resolveUrl(url, this.spec.get(0));
            _memo = { url : url, method : method };
            _successCb = function (data, status, jqXHR) {
                           confirmSuccessCb.call(_this, data, status, jqXHR, _memo);
                         };
            this.spec.attr('disabled', 'disable');
            $.ajax({
              url : url,
              type : method,
              cache : false,
              timeout : 50000,
              success : _successCb,
              error : $.proxy(confirmErrorCb, this)
              });
          } else {
            $axel.error('The command does not know where to send the data');
          }
        }
      };
    }());

    $axel.command.register('confirm', ConfirmCommand, { check : false });

  }());

  /*****************************************************************************\
  |                                                                             |
  |  'autoexec' command object                                                  |
  |                                                                             |
  |  Modal dialog to execute a remote command to chain commands together         |
  |                                                                             |
  \*****************************************************************************/
  (function () {
    function AutoExecCommand ( identifier, node ) {
      this.spec = $(node);
      $('button.ok', node).bind('click', $.proxy(this, 'run'));
    }
    AutoExecCommand.prototype = {
      // Shows modal dialog
      execute : function (event) {
        var title;
        if (this.spec.hasClass('modal')) {
          title = $('success > confirmation', event.command.doc);
          this.spec.find('h3').text(title.text() || 'Missing title');
          this.spec.modal('show');
        } else {
          this.run();
        }
      },
      // Run remote command
      run : function  ( ) {
        var name = this.spec.attr('data-exec'),
            host = this.spec.attr('data-exec-target'),
            target = '#' + this.spec.attr('data-exec-event-target'), // FIXME: resolve here ?
            ev = { synthetic: true };
        if (target) {
          ev.target = target;
        }
        this.spec.modal('hide');
        $axel.command.getCommand(name, host).execute(ev);
      }
    };
    $axel.command.register('autoexec', AutoExecCommand, { check : false });
  }());

  // ********************************************************
  //              Accordion bindings
  // ********************************************************

  // Opens an accordion's tab - Do some inits the first time :
  // - executes commands linked to it (e.g. 'view')
  function openAccordion ( ev ) {
    var n, view, target = $(ev.target);
    if (! (target.hasClass('c-drawer') || target.hasClass('sg-hint') || target.hasClass('sg-mandatory')) ) {
      view = $(this).toggleClass('c-opened');
      if ((view.size() > 0) && !view.data('done')) {
        n = view.first().get(0).axelCommand;
        if (n) {
          n.execute();
        }
        view.data('done',true); // FIXME: seulement si success (?)
      }
    }
  }

  function closeAccordion (ev) {
    var target = $(ev.target);
    if (!$(this).data('done')) { // never activated
      return;
    }
    if (! (target.hasClass('c-drawer') || target.hasClass('sg-hint')) ) {
      $(this).toggleClass('c-opened');
    }
  }

  // ********************************************************
  //          Coaching Plan document bindings
  // ********************************************************

  // Updates all computed values in FundingRequest formular
  function update_frequest() {
    var balance, 
        budget = $axel('#x-freq-Budget'),
        summary = $axel('#x-freq-CurrentActivity'),
        totals = $axel('#x-freq-Totals'),
        contract = $axel('#x-freq-ContractData'),
        all = $axel('#x-freq-FinancialStatement'),
        hr = contract.peek('HourlyRate'),
        nbhours = budget.vector('NbOfHours').sum(),
        // travel = $axel('#x-freq-Travel').peek('Amount'),
        // allowance = $axel('#x-freq-Allowance').peek('Amount'),
        // accomodation = $axel('#x-freq-Accomodation').peek('Amount'),
        fee = Math.round((nbhours * hr)*100)/100;
        // total = Math.round((fee + travel + allowance + accomodation)*100)/100;
        // tasks = $axel('#x-freq-Budget').vector('NbOfHours').product(hr).sum(),
        // other = $axel('#x-freq-OtherExpenses').vector('Amount').sum(),
        // spending = tasks + other,
        // funding = $axel('#x-freq-FundingSources').vector('NbOfHours').sum(),
        // balance = Math.round((funding - spending)*100)/100;
    budget.poke('TotalNbOfHours', nbhours);
    budget.poke('TotalTasks', fee);
  }

  // To be called each time the editor is generated
  function install_frequest() {
    // Tracks user input to recalculate computed fields
    $('#x-freq-Budget')
      .bind('axel-update', update_frequest)
      .bind('axel-add', update_frequest)
      .bind('axel-remove', update_frequest);
  }

  // ********************************************************
  //        Coach Match Integration
  // ********************************************************
  // TODO : move to coach-match.js
  // TODO : manage errors 

  // FIXME: read form action from returned payload (?)
  function open_suggestion ( data, status, xhr ) {
    var payload = xhr.responseText;
    $('#ct-suggest-form > input[name="data"]').val(payload);
    $('#ct-suggest-submit').click();
  }

  // Posts required coach profile to case tracker and retrieve XML payload 
  // for posting to 3rd Coach Match coach suggestion tunnel (see open_suggestion)
  function start_suggestion() {
    var payload = $axel('#c-editor-coaching-assignment').xml();
    $.ajax({
      url : window.location.href + '/match',
      type : 'post',
      async : false,
      data : payload,
      dataType : 'xml',
      cache : false,
      timeout : 50000,
      contentType : "application/xml; charset=UTF-8",
      success : open_suggestion
    });
    // return true;
  }

  function install_coachmatch() {
    $('#ct-suggest-button').click(start_suggestion);
  }

  function init() {
    $('.nav-tabs a[data-src]').click(function (e) {
        var jnode = $(this),
            pane= $(jnode.attr('href') + ' div.ajax-res'),
            url = jnode.attr('data-src');
        pane.html('<p id="c-busy" style="height:32px"><span style="margin-left: 48px">Loading in progress...</span></p>');
        jnode.tab('show');
        pane.load(url, function(txt, status, xhr) { if (status !== "success") { pane.html('Impossible to load the page, maybe your session has expired, please reload the page to login again'); } });
    });

    $('.accordion-group.c-documents').on('shown', openAccordion);
    $('.accordion-group.c-documents').on('hidden', closeAccordion);
    // FundingRequest
    $('#c-editor-funding-request').bind('axel-editor-ready', install_frequest);
    $('#c-editor-funding-request').bind('axel-content-ready', function () { update_frequest(); }); // initialization
    // Coach match tunnel
    $('#c-editor-coaching-assignment').bind('axel-editor-ready', install_coachmatch);
    // Resets content when showing different messages details in modal
    $('#c-alert-details-modal').on('hidden', function() { $(this).removeData(); });
  }

  jQuery(function() { init(); });
}());
