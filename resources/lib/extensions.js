/* ***** BEGIN LICENSE BLOCK *****
 *
 * Copyright (C) 2017 Oppidoc
 *
 * This file contains extensions to the Adaptable XML Editing Library (AXEL) and to the AXEL-FORMS Library
 *
 * License : MIT
 *
 * Web site : http://www.oppidoc.fr, https://bitbucket.org/ssire/axel, https://bitbucket.org/ssire/axel-forms
 * 
 * Contributors(s) : S. Sire
 * 
 * ***** END LICENSE BLOCK ***** */

// TODO: code cleanup and API homogenization (naming conventions)

(function ($axel) {

  var _Constant = {

    ////////////////////////
    // Life cycle methods //
    ////////////////////////

    onGenerate : function ( aContainer, aXTUse, aDocument ) {
      var media = this.getParam('constant_media'),
          htag = (media === 'image') ? 'img' : (((media === 'url') || (media === 'email') || (media === 'file')) ? 'a' : (aXTUse.getAttribute('handle') || 'span')),
          h = xtdom.createElement(aDocument, htag),
          id = this.getParam('id'),
          t;
      if (media !== 'image') { // assumes 'text'
        t = xtdom.createTextNode(aDocument, '');
        h.appendChild(t);
        if ((media === 'url') || (media === 'file')) {
          xtdom.setAttribute(h, 'target', '_blank');
          $(h).click(function(ev) { if ($(ev.target).hasClass('nolink')) { xtdom.preventDefault(ev)}; } );
        }
      }
      if (id) { // FIXME: id to be supported directly as an xt:use attribute (?)
        xtdom.setAttribute(h, 'id', id);
      }
      aContainer.appendChild(h);
      return h;
    },

    onInit : function ( aDefaultData, anOptionAttr, aRepeater ) {
      this._setData(aDefaultData);
      if (this.getParam('hasClass')) {
        xtdom.addClassName(this._handle, this.getParam('hasClass'));
      }
      if (this.getParam('_Output')) {
        this._Output = this.getParam('_Output');
      }
    },

    onAwake : function () {
      // nop
    },

    onLoad : function (aPoint, aDataSrc) {
      var _value, _default, _disp, _output;
      if (aPoint !== -1) {
        _value = aDataSrc.getDataFor(aPoint);
        _default = this.getDefaultData();
        this._setData(_value || _default, aPoint[0].getAttribute('_Display'));
        this.setModified(_value && (_value !==  _default));
        this.set(false);
        this._Output = aPoint[0].getAttribute('_Output');
      } else {
        delete this._Output;
        this.clear(false);
      }
    },

    onSave : function (aLogger) {
      var val, tag, i;
      if ((this.isOptional() && (!this.isSet())) || (this.getParam('noxml') === 'true')) {
        aLogger.discardNodeIfEmpty();
      } else if (this._data) {
        tag = this.getParam('xValue');
        if (tag)  { // special XML serialization from _Output
          if (this._Output) {
            val = this._Output.split(" ");
            for (i = 0; i < val.length; i++) {
              aLogger.openTag(tag);
              aLogger.write(val[i]);
              aLogger.closeTag(tag);
            }
          } else {
            xtiger.cross.log('error', "missing _Output in 'constant' plugin");
          }
        } else {
          val = this.getParam('value');
          aLogger.write(val || this._data);
        }
      }
    },

    ////////////////////////////////
    // Overwritten plugin methods //
    ////////////////////////////////

    api : {
    },

    /////////////////////////////
    // Specific plugin methods //
    /////////////////////////////

    methods : {

      // Sets current data model and updates DOM view accordingly
      _setData : function (aData, display) {
        var base, path, media = this.getParam('constant_media');
        if (media === 'image') {
          if (aData) {
            base = this.getParam('image_base');
            path = base ? base + aData : aData;
          } else {
            path = this.getParam('noimage');
          }
          xtdom.setAttribute(this._handle, 'src', path);
        } else {
          if (this._handle.firstChild) {
            this._handle.firstChild.data = display || aData || '';
          }
          if (media === 'url') {
            path = this._handle.firstChild.data.match(/^(http:\/\/)?(.*)$/);
            xtdom.setAttribute(this._handle, 'href', path[1] ? path[0] : 'http://' + path[2]);
          } else if (media === 'file') {
            if (aData) {
              base = this.getParam('file_base');
              path = base ? base + '/' + aData : aData;
              $(this._handle).removeClass('nolink');
            } else {
              path = '';
              $(this._handle).addClass('nolink');
            }
            xtdom.setAttribute(this._handle, 'href', path);
          } else if (media === 'email') {
            path = this._handle.firstChild.data;
            if (/^\s*$|^\w([-.]?\w)+@\w([-.]?\w)+\.[a-z]{2,6}$/.test(path)) {
              xtdom.setAttribute(this._handle, 'href', 'mailto:' + path);
            } else {
              xtdom.setAttribute(this._handle, 'href', '#'); // FIXME: remove href (?)
            }
          }
          if (this.getParam('constant_colorize') === 'balance') { // DEPRECATED
            this._handle.style.color = (parseInt(aData) >= 0 ) ? 'green' : 'red';
          }
        }

        this._data = aData;
      },

      update : function ( aData ) {
        this._setData(aData.toString());
      },

      dump : function () {
        return this._data;
      },

      // Returns current data model
      getData : function () {
        return this._data;
      },

      // Clears the model and sets its data to the default data.
      // Unsets it if it is optional and propagates the new state if asked to.
      clear : function (doPropagate) {
        this._setData(this.getDefaultData());
        this.setModified(false);
        if (this.isOptional() && this.isSet()) {
          this.unset(doPropagate);
        }
      }
    }
  };

  $axel.plugin.register(
    'constant',
    { filterable: true, optional: true },
    {
      visibility : 'visible'
    },
    _Constant
  );

  /*****************************************************************************\
  |                                                                             |
  |  'augment' command object                                                   |
  |                                                                             |
  |*****************************************************************************|
  |                                                                             |
  |  Required attributes :                                                      |
  |  - data-target : id of the editor which contains the modal window           |
  |      which contains the template to transform to edit/create                |
  |  - data-augment-field : CSS selector of the wrapped set of which the first  |
  |      editing field will be augmented                                        |
  |  - data-augment-root : optional CSS selector of the closest ancestor        |
  |      of the command host to be used to scope the data-augment-field search  |
  |  Note :                                                                     |
  |  - data-template MUST be present on the target modal window                 |
  |  Optional attributes :                                                      |
  |  - data-create-src : URL of the controller to contact to POST new data      |
  |  - data-update-src : URL of the data to update (accepting GET / POST)       |
  |                                                                             |
  \*****************************************************************************/
  function AugmentCommand ( identifier, node ) {
    this.key = identifier;
    this.spec = $(node);
    this.editor = $('#' + identifier);
    this.modal = $('#' + this.spec.attr('data-target') + '-modal');
    this.spec.bind('click', $.proxy(this, 'execute'));
    this.viewing = false;
    node.axelCommand = this;
  }
  AugmentCommand.prototype = {
    // returns AXEL wrapped set for the monitored field(s)
    _getTarget : function () {
      var targetsel = this.spec.attr('data-augment-field'),
          rootsel = this.spec.attr('data-augment-root'),
          scope;
      if (rootsel) {
        scope = this.spec.closest(rootsel).get(0);
        if (scope) {
          return $axel($(targetsel, scope)); // scoped search
        }
      }
      return $axel(targetsel); // full document scope
    },
    _dismiss : function (event) {
      this.editor.unbind('axel-cancel-edit', $.proxy(this, 'cancel'));
      this.editor.unbind('axel-save-done', $.proxy(this, 'saved'));
      this.modal.off('hidden', $.proxy(this, 'cancel'));
      // this.editor.unbind('axel-editor-ready', $.proxy(this, 'stolen'));
      this.modal.modal('hide');
      // $('#' + this.spec.attr('data-target-ui')).hide();
      this.spec.get(0).disabled = false;
      this.viewing = false;
    },
    execute : function (event) {
      var ed = $axel.command.getEditor(this.key),
          win = $('#' + this.spec.attr('data-target')),
          goal = this.spec.attr('data-augment-mode'),
          src = this.spec.attr('data-update-src') || "",
          target, val, tpl;
     if (src && (src.indexOf('$_') !== -1)) {
        target = this._getTarget();
        // val = (target.length() > 1) ? target.get(0).dump() : target.text(); // FIXME: first(), getData() better than dump (AXEL api)
        val = target.get(0).dump();
        if (val) {
          src = src.replace('$_', val);
        } else {
          alert(this.spec.attr('data-augment-noref') || "You must select a name to edit the corresponding record");
          return;
        }
      }
      // sets title depending on goal
      target = win.parent().prev('.modal-header').children('h3').first();
      target.text(target.attr('data-when-' + goal));
      // generates editor
      tpl = win.attr('data-template');
      if (tpl.indexOf("?goal=") !== -1) { // quick fix supposing nothing after
        tpl = tpl.substr(0, tpl.indexOf("?goal="));
      }
      ed.transform(tpl + '?goal=' + goal);
      this.modal.modal('show');
      $('#' + this.spec.attr('data-target') + '-errors').removeClass('af-validation-failed');
      if ($axel(this.editor).transformed() && !this.viewing) { // assumes synchronous transform()
        this.viewing = true;
        this.spec.get(0).disabled = true;
        if (src === "") { // to set where to send data otherwise (creation)
          src = this.spec.attr('data-create-src') || "";
          ed.attr('data-src', src);
          if (!src) {
            xtiger.cross.log('debug','"augment" command with missing "data-create-src"');
          }
        } else {
          $axel(win).load(src);
          ed.attr('data-src', src); // to load data to edit
        }
        this.editor.bind('axel-cancel-edit', $.proxy(this, 'cancel'));
        this.editor.bind('axel-save-done', $.proxy(this, 'saved'));
        this.modal.on('hidden', $.proxy(this, 'cancel'));
        // this.editor.bind('axel-editor-ready', $.proxy(this, 'stolen'));
      }
    },
    // User has clicked cancel or clicked on the closing cross
    cancel : function (event) {
      if (this.viewing) {
        this._dismiss();
        $axel.command.getEditor(this.key).reset(true);
      }
    },
    saved : function (event, editor, source, xhr) {
      var target = this._getTarget().get(0),
          handle = $(target.getHandle()),
          payload = xhr.responseXML,
          name, value;

      this._dismiss();
      // FIXME: check Status="success"
      name = payload.getElementsByTagName("Name")[0].firstChild.data;
      value = payload.getElementsByTagName("Value")[0].firstChild.data;
      if (target && target.getUniqueKey().indexOf('choice') === 0) {
        handle.append('<option value="' + value + '">' + name + '</option>').val(value); // adds option and simulates user input
      }
      target.update(value);
      // handle.removeClass('select2-offscreen');
      if (target && target.getUniqueKey().indexOf('choice') === 0) {
        handle.trigger('change', { synthetic: true }); // propagates change (e.g. 'select2' filter needs it
        $axel.command.getEditor(this.key).reset(true);
      }
    }
    // Some other document editor loaded (only useful if non modal popup windows)
    // stolen : function (event) {
    //   if (this.viewing) {
    //     this._dismiss();
    //   }
    // }
  };

  $axel.command.register('augment', AugmentCommand, { check : false });

  /*****************************************************************************\
  |                                                                             |
  |  AXEL 'autofill' filter                                                     |
  |                                                                             |
  |  Listens to a change of value in its editor caused by user interaction      |
  |  (and not by loading data), then submit the change to a web service         |
  |  and loads its response into a target inside the editor.                    |
  |                                                                             |
  |*****************************************************************************|
  |                                                                             |
  |  Optional attributes :                                                      |
  |  - autofill_container : CSS selector of the HTML element containing the     |
  |      editor containing the target field, when this parameter is defined     |
  |      the filter also react to 'axel-content-ready' (editor's load           |
  |      completion event), this is useful for implementing lightweight         |
  |      transclusion                                                           |
  |  - autofill_root / autofill_target : CSS selector(s) of the subtree to fill |
  |      with data, if not defined filling starts at the first ancestor         |
  |      of the host element handle that matches autofill_target selector       |
  |                                                                             |
  |  Prerequisites :                                                            |
  |  - the web service MUST return an XML fragment compatible with the target   |
  |  - jQuery                                                                   |
  \*****************************************************************************/

  var _AutoFill = {

    onAwake : function () {
      var c = this.getParam('autofill_container');
      this.__autofill__onAwake();
      if (c) {
        // cannot directly subscribed to $(this.getHandle()).closest(c) since the generated editor has not yet been plugged into the container
        // FIXME: extend AXEL with a onEditorReady life cycle method (?)
        $(document).bind('axel-content-ready', $.proxy(this, 'contentLoaded'));
      }
    },

    //////////////////////////////////////////////////////
    // Overriden specific plugin methods or new methods //
    //////////////////////////////////////////////////////
    methods : {
      update : function (aData) {
        if (! this._autofill_running) {
          alert('autofill updating ' + aData);
          this.__autofill__update(aData);
          this.autofill();
        } // FIXME: short-circuit to avoid reentrant calls because select2 triggers 'change' on load
          // to synchronize it's own implementation with 'choice' model which triggers a call to update as a side effect...
      },
      contentLoaded : function (event, sourceNode) {
        if (sourceNode === $(this.getHandle()).closest(this.getParam('autofill_container')).get(0)) {
          this.autofill();
        }
      },
      autofill : function (event) {
        var target = this.getParam('autofill_target'),
            value = this.dump(), // FIXME: use getData ?
            url = this.getParam('autofill_url');
        alert('calling autofill ' + target + ' with value ' + value);
        if (target) { // sanity check
          if (value && url) { // sanity check
            if (!(event) || (event.target !== $(this.getHandle()).closest(target).get(0))) {
              // guard test is to avoid reentrant call since load() will trigger a bubbling 'axel-content-ready' event
              // FIXME: alternative solution si to extend load API with stg like load(url, { triggerEvent: false }) or load(url, { eventBubbling: false })
              url = url.replace(/\$_/g, value);
              this._autofill_running = true;
              $axel($(this.getHandle()).closest(target)).load(url);
              // $axel($(target, this.getDocument())).load(url);
              this._autofill_running = false;
              alert('after calling autofill ' + target + ' with value ' + this.dump());
            }
          } if (!value) {
            this._autofill_running = true;
            $axel($(this.getHandle()).closest(target)).load('<Reset/>'); // FIXME: implement $axel().reset()
            this._autofill_running = false;
          }
        }
      }
    }
  };

  $axel.filter.register(
    'autofill',
    { chain : [ 'update', 'onAwake' ] },
    { },
    _AutoFill
  );
  $axel.filter.applyTo({'autofill' : ['choice','constant']});

  /*****************************************************************************\
  |                                                                             |
  |  'c-delete' command object                                                    |
  |                                                                             |
  \*****************************************************************************/
  (function () {
    function DeleteCommand ( identifier, node ) {
      this.spec = $(node);
      this.spec.bind('click', $.proxy(this, 'execute'));
    }
    DeleteCommand.prototype = {

      // FIXME: manage server side error messages (and use 200 status)
      successCb : function (response, status, xhr) {
        var loc = xhr.getResponseHeader('Location'),
            proceed, target;
        if (loc) { // one shot protocol
          window.location.href = loc;
        } else if (xhr.status === 202) { // middle of transactional protocol
          proceed = confirm($('success > message', xhr.responseXML).text());
          if (proceed) {
            $.ajax({
              url : this.controller,
              // type : 'delete',
              type : 'post',
              data :  { '_delete' : 1 },
              cache : false,
              timeout : 20000,
              success : $.proxy(this, "successCb"),
              error : $.proxy(this, "errorCb")
            });
          }
        } else if (xhr.status === 200) { // end of transactional protocol
          alert($('success > message', xhr.responseXML).text());
          target = this.spec.attr('data-target'); // triggers 'axel-delete-done' on the target editor
          if (target) {
            target = $axel.command.getEditor(target);
            if (target) {
              target.trigger('axel-delete-done', this, xhr);
            }
          }
        } else {
          this.spec.trigger('axel-network-error', { xhr : xhr, status : "unexpected" });
        }
        this.spec.triggerHandler('axel-transaction-complete', { command : this });
      },

      errorCb : function (xhr, status, e) {
        this.spec.trigger('axel-network-error', { xhr : xhr, status : status, e : e });
        this.spec.triggerHandler('axel-transaction-complete', { command : this });
      },

      execute : function () {
        var ask = this.spec.attr('data-confirm'),
            target = this.spec.attr('data-target'),
            request = {
                  cache : false,
                  timeout : 20000,
                  success : $.proxy(this, "successCb"),
                  error : $.proxy(this, "errorCb")
                },
            proceed = true,
            ed, ctrl;

        if (ask) { // one shot version : directly send 'delete' action
          proceed = confirm(ask);
          request.type = 'post'; // should be 'delete' but we had pbs with tomcat / realm
          request.data = { '_delete' : 1 };
        } else { // transactional version : first request confirmation message from server with 'post' then send 'delete'
          request.type = 'post';
        }
        if (target) { // attached to an editor
          ed = $axel.command.getEditor(target);
          if (ed) {
            ctrl = ed.attr('data-src');
            if (ctrl) {
              if (/\.[\w\?=]*$/.test(ctrl)) {   // replaces end of URL with '/delete' (eg: .blend or .xml?goal=update)
                ctrl = ctrl.replace(/\.[\w\?=]*$/, '/delete');
              } else {
                ctrl = ctrl + '/delete';
              }
            }
          }
        }
        this.controller = ctrl || this.spec.attr('data-controller');
        if (proceed) {
          request.url = this.controller;
          this.spec.triggerHandler('axel-transaction', { command : this });
          $.ajax(request);
        }
      }
    };
    $axel.command.register('c-delete', DeleteCommand, { check : false });
  }());

  /*****************************************************************************\
  |                                                                             |
  |  'c-inhibit' command object                                                    |
  |                                                                             |
  \*****************************************************************************/
  (function () {
    // User has clicked on a 'save' command trigger
    function startSave (event) {
      var spec = event.data,
          menu = spec.closest('.c-menu-scope');
      menu.find('button, a').hide();
      menu.append($('#c-saving').children('span.c-saving').clone(false));
    }

    // A 'save' action is finished
    function finishSave (event) {
      var spec = event.data;
          menu = spec.closest('.c-menu-scope');
      menu.find('button, a').show();
      menu.children('span.c-saving').remove('.c-saving');
    }

    function InhibitCommand ( identifier, node ) {
      var spec = $(node),
          sig = spec.attr('data-command');
      if (sig.indexOf('save') !== -1) { // on 'save' command
        $('#' + spec.attr('data-target'))
          .bind('axel-save', spec, startSave)
          .bind('axel-save-done', spec, finishSave)
          .bind('axel-save-error', spec, finishSave)
          .bind('axel-save-cancel', spec, finishSave);
      } else { // on 'status' or 'c-delete' command
        spec
          .bind('axel-transaction', spec, startSave)
          .bind('axel-transaction-complete', spec, finishSave);
      }
    }
    $axel.command.register('c-inhibit', InhibitCommand, { check : false });
  }());

  /*****************************************************************************\
  |                                                                             |
  |  'attachment' plugin to view an attachment inside a form                    |
  |                                                                             |
  \*****************************************************************************/
  (function ($axel) {

    // you may use the closure to declare private objects and methods here

    var _Editor = {

      ////////////////////////
      // Life cycle methods //
      ////////////////////////
      onGenerate : function ( aContainer, aXTUse, aDocument ) {
        var viewNode = xtdom.createElement (aDocument, 'div');
        aContainer.appendChild(viewNode);
        return viewNode;
      },

      onInit : function ( aDefaultData, anOptionAttr, aRepeater ) {
        if (this.getParam('hasClass')) {
          xtdom.addClassName(this._handle, this.getParam('hasClass'));
        }
      },

      // Awakes the editor to DOM's events, registering the callbacks for them
      onAwake : function () {
      },

      onLoad : function (aPoint, aDataSrc) {
        var i, h;
        if (aDataSrc.isEmpty(aPoint)) {
          $(this.getHandle()).html('');
         } else {
           h = $(this.getHandle());
           h.html('');
           for (i = 1; i < aPoint.length; i++) {
             h.append(aPoint[i]);
           }
        }
      },

      onSave : function (aLogger) {
        aLogger.write('HTML BLOB');
      },

      ////////////////////////////////
      // Overwritten plugin methods //
      ////////////////////////////////
      api : {
      },

      /////////////////////////////
      // Specific plugin methods //
      /////////////////////////////
      methods : {
      }
    };

    $axel.plugin.register(
      'attachment',
      { filterable: false, optional: false },
      {
       key : 'value'
      },
      _Editor
    );

  }($axel));

  /*****************************************************************************\
  |                                                                             |
  |  'switch' binding for conditional viewing                                   |
  |                                                                             |
  |  This is a rewrite of original 'condition' binding                          |
  |                                                                             |
  \*****************************************************************************/
  (function ($axel) {

    var _Switch = {

      onInstall : function ( host ) {
        this.disableClass = this.getParam('disable-class');
        this.avoidstr = 'data-avoid-' + this.getVariable();
        this.editor = $axel(host);
        host.bind('axel-update', $.proxy(this.updateConditionals, this));
        // command installation is post-rendering, hence we can change editor's state
        this.updateConditionals();
        // FIXME: should be optional (condition_container=selector trick as 'autofill' ?)
        $(document).bind('axel-content-ready', $.proxy(this, 'updateConditionals'));

      },

      methods : {

        // onset.foreach( addClass data-on-class, removeClass data-off-class )
        // offset.foreach( removeClass data-on-class, addCLass data-off-class )

        updateConditionals : function  (ev, editor) {
          var onset, offset;
          var curval = this.editor.text();
          var fullset = $('body [' + this.avoidstr + ']', this.getDocument());
          onset = (curval !== '') ? fullset.not('[' + this.avoidstr + '*="' + curval + '"]') : fullset.not('[' + this.avoidstr + '=""]');
          offset = (curval !== '') ? fullset.filter('[' + this.avoidstr + '*="' + curval + '"]') : fullset.filter('[' + this.avoidstr + '=""]');
          // data-disable-class rule
          if (this.disableClass) {
            onset.removeClass(this.disableClass);
            offset.addClass(this.disableClass);
          }
          // data-(on | off)-class distributed rules
          onset.filter('[data-on-class]').each(function (i, e) { var n = $(e); n.addClass(n.attr('data-on-class')); } );
          offset.filter('[data-on-class]').each(function (i, e) { var n = $(e); n.removeClass(n.attr('data-on-class')); } );
          onset.filter('[data-off-class]').each(function (i, e) { var n = $(e); n.removeClass(n.attr('data-off-class')); } );
          offset.filter('[data-off-class]').each(function (i, e) { var n = $(e); n.addClass(n.attr('data-off-class')); } );
        }
      }
    };

    $axel.binding.register('switch',
      null, // no options
      { 'disable-class' : undefined }, // parameters
      _Switch);
  }($axel));

  /*****************************************************************************\
  |                                                                             |
  |  'open' command object                                                    |
  |                                                                             |
  \*****************************************************************************/
  (function () {
    function doOpen (event) {
      var spec = event.data,
          f = $('#' + spec.attr('data-form')),
          action = $axel.resolveUrl(spec.attr('data-src'));
      f.attr('action', action);
      f.submit();
    }
    function OpenCommand ( identifier, node ) {
      var spec = $(node);
      spec.bind('click', spec, doOpen);
    }
    $axel.command.register('open', OpenCommand, { check : false });
  }());
  
  /************************************************************************************\
  |                                                                                    |
  |  'show' command object to open a modal with content depending on an editing field  |
  |                                                                                    |
  \************************************************************************************/
  (function () {
    function ShowCommand ( identifier, node ) {
      this.spec = $(node);
      this.key = identifier;
      this.spec.bind('click', $.proxy(this, 'execute'));
    }
    ShowCommand.prototype = {
      execute : function (event) {
        var dial = this.spec.attr('data-target-modal'),
            ptr  = this.spec.attr('data-value-source'),
            val  = $axel(ptr).text(),
            url  = this.spec.attr('data-src').replace('$_', val),
            pane = $('#' + dial + ' .modal-body');
        if (val) {
          pane.load(url,
            function(txt, status, xhr) {
              if (status !== "success") { pane.html('Error while loading page'); }
            }
          );
        } else {
          pane.html('You must select a value first');
        }
        $('#' + dial).modal('show');
      }
    };
    $axel.command.register('show', ShowCommand, { check : false });
  }());

}($axel));



/*****************************************************************************\
|                                                                             |
|  AXEL 'mandatory' binding                                                   |
|                                                                             |
|*****************************************************************************|
|  Prerequisites: jQuery, AXEL, AXEL-FORMS                                    |
|                                                                             |
\*****************************************************************************/

// TODO: make data-regexp optional if data-pattern is defined for HTML5 validation only

(function ($axel) {

  var _Mandatory = {

    onInstall : function ( host ) {
      var root, jroot;
      var doc = this.getDocument();
      this.editor = $axel(host);
      this.spec = host;

      host.bind('axel-update', $.proxy(this.check, this));
      $axel.binding.setValidation(this.editor.get(0), $.proxy(this.validate, this));
    },

    methods : {

      // Updates inline bound tree side-effects based on current data
      check : function  (when) {
        var valid = this.editor.text() != '',
            scope,
            label,
            doc = this.getDocument(),
            anchor = this.spec.get(0),
            iklass = this.spec.attr('data-mandatory-invalid-class'),
            type = this.spec.attr('data-mandatory-type'),
            // select2/choice2 plugin graphic control 
            a = this.spec.find('a.[class*="select2-choice"]'),
            k = this.spec.find(type).first().attr('class');

        if (a.length > 0) {
          k = a.first().attr('class');
          if (valid && k.indexOf(iklass) !== -1) {
            a.first().attr('class', k.substring(0, k.indexOf(iklass) - 1));
          } else if (!valid && k.indexOf(iklass) == -1) {
            a.first().attr('class', k + ' ' + iklass);
          }
        } else if (k) {
          if (valid && k.indexOf(iklass) !== -1) {
            this.spec.find(type).first().attr('class', k.substring(0,k.indexOf(iklass) - 1));
          } else if (!valid && k.indexOf(iklass) == -1) {
            this.spec.find(type).first().attr('class', k + ' ' + iklass);
          }
        }
        return valid;
      },
      
      // Updates inline bound tree side-effects based on current data
      // Returns true to block caller command (e.g. save) if invalid
      // unless data-validation is 'off'
      validate : function () {
        var res = this.check();
        return (this.spec.attr('data-validation') === 'off') || res;
      }
    }
  };

  $axel.binding.register('mandatory',
    { error : true  }, // options
    {  }, // parameters
    _Mandatory
  );

}($axel));

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


