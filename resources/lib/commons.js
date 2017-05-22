/* XQuery Content Management Widgets
 *
 * author      : Stéphane Sire
 * contact     : s.sire@oppidoc.fr
 * license     : LGPL v2.1
 * last change : 2016-09-30
 *
 * AXEL and AXEL-FORMS plugins and filters for Oppidum applications
 * AXEL-FORMS commands and bindings for Oppidum applications
 *
 * Prerequisites: jQuery + AXEL + AXEL-FORMS + d3.js (table factory)
 *
 * List of widgets
 * - table factory : $axel.command.makeTableCommand
 * - 'table' command
 *
 * Copyright (c) 2016 Oppidoc SARL, <contact@oppidoc.fr>
 */

/*****************************************************************************\
|                                                                             |
|             Table factory $axel.command.makeTableCommand                    |
|                                                                             |
| - generates and registers '{name}-table' commands from a model hash         |
|   and a row encoding function (dependency injection)                        |
| - implements the Ajax JSON table protocol                                   |
|                                                                             |
| Hosting :                                                                   |
| - data-command='{name}-table' data-table-configure='sort filter'            |
|   on pre-generated table element                                            |
| - pre-generate table headers with data-sort="key" and data-filter="key"     |
|   for sortable / filterable columns                                         |
|                                                                             |
\*****************************************************************************/
(function () {

  function _makeTableCommand ( name, encodeRowFunc, tableRowModel ) {
    var kommand = new Function(
                        ['key', 'node'],
                        'this.spec = $(node); this.table = this.spec.attr("id"); this.spec.bind("click",$.proxy(this,"handleAction")); this.modals={};this.config={};this.configure(this.spec.attr("data-table-configure"));'
                      );

    kommand.prototype = (function (encodeRowFunc, tableRowModel) {

      var _myEncodeRowFunc = function (d) { return encodeRowFunc(d, _encodeCell); },
          _myRowModel = tableRowModel,
          _mySorts = {},
          _name = name;

      // Forwards $.ajax errors to application global error handler
      function _jqForwardError ( xhr, status, e )  {
        // TODO: hide spoining wheel $('#' + this.spec.attr('data-busy')).hide();
        $('body').trigger('axel-network-error', { xhr : xhr, status : status, e : e });
      }

      // Return datum used to generate target's row
      // FIXME: not robust
      function _getDatum ( target ) {
        return d3.select(target.parent().parent().get(0)).data()[0];
      }

      // Utility to encode $_ and $.name variables in a string
      // Useful to interpret URL string in results table specification language
      function _encodeVariables ( str, datum ) {
        var buffer = str;
        if (buffer.indexOf('$.') !== -1) {
          buffer = buffer.replace(/\$\.([\w-]*)/g, function (str, varname) { return datum[varname]; });
        }
        return buffer.replace('$_', datum.Id);
      }

      // Generic column sort callback
      function _sortByHeaderCallback (ev) {
        var t = $(ev.target).closest('th'),
            table = t.closest('table'),
            tabctrl = $axel.command.getCommand(table.attr('data-command'), table.attr('id')),
            sortKey = t.attr('data-sort');

        if ((ev.target.nodeName.toUpperCase() !== 'INPUT') && tabctrl.sort) { // avoid filter input
          if (sortKey.charAt(0) === '-') { // inverse sort
            tabctrl.sort(sortKey.substr(1), true);
          } else {
            tabctrl.sort(sortKey);
          }
        }
      }

      // Default filter function
      function _filter(d, key, value) {
        return d[key] && (d[key].toUpperCase().indexOf(value) !== -1);
      }

      // Returns data encoding of a single cell for rendering
      function _encodeCell(key, data) {
        var val;
        if (data === undefined) {
          val = undefined;
        } else if (typeof data === 'string') {
          val = data;
        } else {
          val = data[key];
        }
        return { 'key' : key, 'value' : val};
      }

      // Renders a single encoded cell using a given model
      function _renderCell(d, i) {
        var model;
        if (d && typeof d === "object") {
          if (d.key) {
            model = _myRowModel[d.key];
            if (d.value) {
              if (model.yes === '*') {
                return '<a target="_blank">' + d.value + '</a>';
              } else if (model.yes === '@') {
                return '<a href="mailto:' + d.value + '">' + d.value + '</a>';
              } if (model.yes === '.') {
                return d.value;
              } else {
                return model.yes;
              }
            } else if (model.button) {
              return model.button;
            } else {
              return model.no;
            }
          } else {
            xtiger.cross.log('error', 'missing "key" property to render cell in '+ _name + ' table');
          }
        } else { // most probably "string" or "number"
          return d;
        }
      }

      return {

        // run once (triggered by data-table-configure)
        configure : function ( spec ) {
          if (spec) {
            if (spec.indexOf('sort') !== -1) {
              if (!this.config.sort) {
                this.spec.find("th[data-sort]").bind("click", _sortByHeaderCallback);
                this.config.sort = true;
              }
            }
            if (spec.indexOf('filter') !== -1) {
              if (!this.config.filter) {
                this.spec.find("th[data-filter] input").bind('keyup', $.proxy(this, 'filter'));
                this.config.filter = true;
              }
            }
          }
        },

        // Change sort order if column already sorted, otherwise start with descending order
        // WARNING: d3.ascending(x, y) === 1 means
        // * x is superior to y (x, y numbers), thus they will be inverted when sorted
        // * x is after y in alphabetical order (x, y string), thus they will be inverted when sorted
        // thus for column display we use the term descending as sorted in alphabetical order
        // (hence the - prefix to inverse values encoded as numbers)
        sort : function (name, inverse) {
          var model = _myRowModel[name],
              d3rows = d3.select('#' + this.table + ' tbody').selectAll('tr'),
              jtable, jheader, sortFunc, ascend;
          if (d3rows.size() > 1) {
            jtable = $('#' + this.table);
            jheader = jtable.find('th[data-sort$=' + name +']');
            if ((_mySorts[name] === undefined) || ((!jheader.hasClass('ascending') && !(jheader).hasClass('descending')))) {
              ascend = true;
            } else {
              ascend = _mySorts[name] === true ? false : true;
            }
            if (model) {
              _mySorts[name] = ascend;
              if (inverse) {
                ascend = !ascend;
              }
              if (ascend) {
                sortFunc = _myRowModel[name].ascending || function (a, b) { return d3.ascending(a[name], b[name]); };
              } else {
                sortFunc = _myRowModel[name].descending || function (a, b) { return d3.descending(a[name], b[name]); };
              }
              if (sortFunc) { // TODO: spinning wheel ?
                d3rows.sort(sortFunc);
                jtable.find('th').removeClass('ascending').removeClass('descending');
                if ((inverse && !ascend) || (!inverse && ascend)) {
                  jheader.addClass('descending');
                } else {
                  jheader.addClass('ascending');
                }
              } else {
                xtiger.cross.log('error','table sort missing ordering functions for key ' + name);
              }
            } else {
              xtiger.cross.log('error','table sort unkown column model for key ' + name);
            }
          }
        },

        filter : function () {
          var filters = []; // array of test function (one per column)
          this.spec.find("th[data-filter] input").each(
            function (i, e) {
              var input = $(e),
                  key = input.closest('th').attr('data-filter'),
                  val = input.val(),
                  test, model, filterFunc;
              if (key && val && val !== '') {
                test = val.toUpperCase();
                model = _myRowModel[key];
                if (model && model.filter) {
                  filterFunc = function(d) { return model.filter(d, key, test); }
                } else {
                  filterFunc = function(d) { return _filter(d, key, test); }
                }
                filters.push(filterFunc);
              }
            }
          );

          d3.select('#' + this.table + ' tbody').selectAll('tr').style('display',
            function (d) {
              var i;
              for (i = 0; i < filters.length; i++) {
                if (!filters[i](d)) {
                  return 'none';
                }
              };
              return 'table-row';
            }
          );
        },
        
        reset : function () {
          // hides sort arrows (does not return to primitive order !)
          $('#' + this.table).find('th').removeClass('ascending').removeClass('descending');
          // clean filters input and show again all rows
          this.spec.find("th[data-filter] input").each( function (i, e) { $(e).val(''); } );
          d3.select('#' + this.table + ' tbody').selectAll('tr').style('display', 'table-row');
        },

        // Replaces row data matching data.Id as row key, fallbacks to data.Email
        updateRow : function ( data ) {
          var uid, email, cells;
          if (data) {
            uid = data.Id;
            email = data.Email;
            d3.select('#' + this.table + ' tbody').selectAll('tr').each(
              function (d, i) {
                if ((uid && (d.Id === uid)) || (email && (d.Email === email))) {
                  // update row cells
                  cells = d3.select(this).data([ data ]).selectAll('td').data(_myEncodeRowFunc);
                  cells.html(_renderCell);
                }
              }
            )
            $('#' + this.table).find('th').removeClass('ascending').removeClass('descending');
          }
        },

        // Prepends a new row with data
        insertRow : function ( data ) {
          if (data) {
            d3.select('#' + this.table + ' tbody')
              .insert('tr', ':first-child')
              .data([ data ])
              .selectAll('td')
              .data(_myEncodeRowFunc)
              .enter()
              .append('td').html(_renderCell);
            $('#' + this.table).find('th').removeClass('ascending').removeClass('descending');
          }
        },

        // Removes a row matching an id
        removeRowById : function ( id ) {
          d3.select('#' + this.table + ' tbody').selectAll('tr').each(
            function (d, i) {
              if (id && (d.Id === id)) {
                cells = d3.select(this).remove();
              }
            }
          )
        },

        // Returns DOM node for row (tr element) matching an id
        getRowById : function ( id ) {
          var res;
          d3.select('#' + this.table + ' tbody').selectAll('tr').each(
            function (d, i) {
              if (id && (d.Id === id)) {
                res = this;
              }
            }
          )
          return res;
        },

        // Interprets JSON Ajax success response protocol
        // Event handler tailored for AXEL 'save' command callback parameters
        // By default subscribed to 'axel-save-done' and 'axel-delete-done' from modal editors
        // TODO: implement remove Action
        // TODO: use Oppidum parse function to handle other Ajax reponses (message, forward)
        ajaxSuccessResponse : function (event, editor, command, xhr) {
          var response = JSON.parse(xhr.responseText),
              table, payload;
          if (response.payload) {
            payload = response.payload;
            if (payload.Table === _name) {
              if (payload['Users']) { // FIXME: replace by Rows ?
                if (payload.Action === 'delete') {
                  this.removeRowById(payload.Users.Id);
                } else if (payload.Action === 'update') {
                  this.updateRow(payload.Users);
                } else if (payload.Action === 'create') {
                  this.insertRow(payload.Users);
                }
              } else {
                xtiger.cross.log('error', _name + ' table received Ajax response w/o Users payload');
              }
            } else {
              xtiger.cross.log('error', _name + ' table dismiss ajax response for ' + payload.Table);
            }
          }
        },

        submitAjaxSuccess : function ( data, status, xhr ) {
          this.ajaxSuccessResponse('axel-save-done', null, null, xhr);
        },

        // Table click event dispatcher based on table model
        handleAction : function (ev) {
          var target = $(ev.target),
              key, modal, uid, src, ctrl, template, wrapper, action, callback, ajax,
              GEN = _myRowModel,
              hotspot = ev.target.nodeName.toUpperCase();
          if ((hotspot === 'A') || (hotspot === 'BUTTON')) {
            // 1. find key to identify target editor or action
            uid = _getDatum(target).Id; // tr datum
            key = d3.select(target.parent().get(0)).data()[0].key; // td datum
            editor = GEN[key].editor;
            action = target.attr('data-action');
            if (action) {
              if (GEN[key].callback) {
                callback = GEN[key].callback[action];
              } else if (GEN[key].ajax) {
                ajax = GEN[key].ajax[action];
              }
            } else {
              callback = GEN[key].callback;
              ajax = GEN[key].ajax;
            }
            // 2. transform editor, load data, show modal
            if (editor) { // shows corresponding modal editor
              src = GEN[key].resource ? GEN[key].resource.replace('$_', uid).replace('$\#', _name) : undefined;
              ctrl = GEN[key].controller ? GEN[key].controller.replace('$_', uid).replace('$\#', _name) : undefined;
              template = GEN[key].template ? GEN[key].template.replace('$_', uid) : undefined;
              if (src.indexOf('$!') !== 0) {
                src = src.replace('$!', d3.select(target.parent().parent().get(0)).data()[0].RemoteLogin);
              }
              wrapper = $axel('#' + editor);
              // src = src + ".xml?goal=" + goal;
              ed = $axel.command.getEditor(editor);
              if (wrapper.transformed()) { // template reuse
                if (template) { // update template and data
                  ed.transform(template, src);
                } else { // just load data (single template editor ?)
                  ed.load(src);
                }
                $('#' + editor + ' .af-error').hide();
                $('#' + editor + '-errors').removeClass('af-validation-failed');
                if (wrapper.transformed()) {
                  $('#' + editor + '-modal').modal('show');
                  if (ctrl) {
                    ed.attr('data-src', ctrl);
                  }
                }
              } else { // first time
                if (template) {
                  ed.attr('data-template', template);
                }
                ed.attr('data-src', src);
                ed.transform();
                if (ctrl) {
                  ed.attr('data-src', ctrl);
                }
                if (wrapper.transformed()) {
                  $('#'+ editor).bind('axel-cancel-edit', function() { $('#' + editor + '-modal').modal('hide'); });
                  $('#' + editor + '-modal').modal('show');
                }
              }
              if (!this.modals[editor]) { // registers once Ajax response handler for that modal
                this.modals[editor] = $.proxy(this, "ajaxSuccessResponse");
                $('#' + editor).bind('axel-save-done', this.modals[editor]);
                $('#' + editor).bind('axel-delete-done', this.modals[editor]);
              }
            } else if (GEN[key].open) { //open url action
              action = _encodeVariables(GEN[key].open, _getDatum(target))
              target.attr('href', action); // dynamically sets URL and opens link
              target.click(function (event) { // avoid too much recursion due to recursive clicking on table
                event.stopPropagation();
              });
              target.click();
            } else if (callback) {
              callback(uid, key, target);
            } else if (ajax) {
              // TODO: deactivate command - spining wheel $('#cm-mgt-busy').show();
              $.ajax({
                url : _encodeVariables(ajax.url, _getDatum(target)),
                type : 'post',
                async : false,
                data : ajax.payload,
                dataType : 'json',
                cache : false,
                timeout : 50000,
                contentType : "application/xml; charset=UTF-8",
                success : $.proxy(this, "submitAjaxSuccess"),
                error : _jqForwardError
              });
            } else if (GEN[key].modal) { // loads content into modal box
              src = GEN[key].resource ? GEN[key].resource.replace('$_', uid).replace('$\#', _name) : undefined;
              modal = $('#' + GEN[key].modal);
              modal.find('.modal-body')
                .html('<p>Loading</p>') // TODO: spinning wheel
                .load(src,
                  function(txt, status, xhr) {
                    var msg = $axel.oppidum.getOppidumErrorMsg(xhr)
                    if (status !== "success") {
                      modal.html('Error loading content (' + msg + '), sorry for the inconvenience');
                    }
                  }
                );
              modal.modal('show');
            }
          }
        },

        // Generates table rows with d3
        execute : function( data, update ) {
          var table = d3.select('#' + this.table).style('display', 'table'),
              rows,
              cells;

          // reset sorting and filters
          this.reset();
          if (!update) {
            // table rows maintenance
            rows = table.select('tbody').selectAll('tr').data(data);
            rows.enter().append('tr');
            rows.exit().remove();

            // cells maintenance
            cells = table.select('tbody').selectAll('tr').selectAll('td').data(_myEncodeRowFunc);
            cells.html(_renderCell); // update
            cells.enter().append('td').html(_renderCell); // create
            cells.exit().remove(); // delete
          } else {
            // FIXME: rewrite using full d3 API (no need for for ?)
            for (var i=0; i < data.length; ++i) {
            	table.select('tbody').append('tr').data( [ data[i] ]).selectAll('td').data(_myEncodeRowFunc).enter().append('td').html(_renderCell);
            }
          }
          return this;
        }
      };
    }(encodeRowFunc, tableRowModel)); // end of prototype generation

    $axel.command.register(name +'-table', kommand, { check : false });
  }

  $axel.command.makeTableCommand = _makeTableCommand;
}());

/*****************************************************************************\
|                                                                             |
|                         'table' command                                     |
|                                                                             |
| - Manages click on a button trigger to submit a search request from an      |
|   editor content and show results in a table using Ajax JSON table protocol |
|                                                                             |
| Hosting :                                                                   |
| - data-command='table'                                                      |
| - data-target='editor' : XTiger editor id for payload                       |
| - data-controller='url' : controller URL for the POST request               |
| - data-busy='id' : optional id of a spinning wheel element to show progress |
|                                                                             |
\*****************************************************************************/
(function () {
  function TableCommand ( identifier, node ) {
    this.key = identifier;
    this.spec = $(node);
    this.spec.bind('click', $.proxy(this, 'execute'));
  }

  TableCommand.prototype = {

    // Forwards $.ajax errors to application global error handler
    _jqForwardError : function ( xhr, status, e )  {
      $('#' + this.spec.attr('data-busy')).hide();
      $('body').trigger('axel-network-error', { xhr : xhr, status : status, e : e });
    },
    
    // Implements Ajax JSON table protocol response
    // Expects: DB.Table (name of table), DB.Users (rows)
    // Works on #{table}-results table element and #{table}-summary feedback summary element
    _submitSearchSuccess : function ( data, status, xhr ) {
      var DB = (data.Users === undefined || $.isArray(data.Users)) ? data.Users : [ data.Users ],
          jsum = $('#' + data.Table + '-summary'),
          nb;
      $('#' + this.spec.attr('data-busy')).hide();
      if (DB) { // something to show
        //$('#no-sample').hide();
        nb = data.Users ? data.Users.length || 1 : 0;
        jsum.find('.xcm-counter').text(nb);
        if (nb > 1) {
          jsum.find('.xcm-plural').show();
          jsum.find('.xcm-singular').hide();
        } else {
          jsum.find('.xcm-plural').hide();
          jsum.find('.xcm-singular').show();
        }
        jsum.show();
        try {
          $axel.command.getCommand(data.Table + '-table', data.Table + '-results').execute(DB);
        } catch (e) {
          alert('Exception [' + e.name + ' / ' + e.message + '] please contact application administrator !');
        }
      } else { // nothing to show
        //$('#no-sample').show();
        jsum.find('.xcm-counter').text(0);
        jsum.find('.xcm-plural').hide();
        jsum.find('.xcm-singular').show();
        jsum.show();
        d3.selectAll('#' + data.Table + '-results').style('display', 'none');
      }
    },    

    execute : function (event) {
      var payload = $axel("#" + this.key).xml();
      $('#' + this.spec.attr('data-busy')).show();
      $.ajax({
        url : this.spec.attr('data-controller'),
        type : 'post',
        async : false,
        data : payload,
        dataType : 'json',
        cache : false,
        timeout : 50000,
        contentType : "application/xml; charset=UTF-8",
        success : $.proxy(this, '_submitSearchSuccess'),
        error : $.proxy(this, '_jqForwardError')
      });
    }
  }

  $axel.command.register('table', TableCommand, { check : false });
}());

