// DEPRECATED : you most likely will have a workflow.js per-application to implement computed fields in workflow view

(function () {

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
