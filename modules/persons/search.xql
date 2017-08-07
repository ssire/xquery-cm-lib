xquery version "1.0";
(: --------------------------------------
   XQuery Content Management Library

   Brings up members search page with default search submission results
   or execute a search submission (POST) to return an HTML fragment.
   
   Mixed search controller that manages both persons and coaches search requests

   This is a sample file for Case Tracker Pilote

   You MOST probably will need to copy this file to your 
   project to customize it to fit your application data model

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   FIXME:
   - return 200 instead of 201 when AXEL-FORM will have been changed

   January 2015 - (c) Copyright 2015 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

declare namespace xdb = "http://exist-db.org/xquery/xmldb";

import module namespace request="http://exist-db.org/xquery/request";
import module namespace search = "http://oppidoc.com/ns/xcm/search" at "search.xqm";
import module namespace submission = "http://oppidoc.com/ns/xcm/submission" at "../submission/submission.xqm";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace access = "http://oppidoc.com/ns/xcm/access" at "../../lib/access.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

declare function local:gen-search-ui ( $coach as xs:boolean, $create as xs:boolean, $tag as xs:string, $ctrl as xs:string, $tpl as xs:string ) as element()* 
{
  let $preview := request:get-parameter('preview', ())
  return (
    <Formular Id="editor" Width="680px">
      <Template loc="form.title.persons.search">templates/search/{ $tpl }</Template>
      {
      if (not($preview)) then
        <Submission Controller="{ $ctrl }">{ concat('persons/submission','?name=', $tag) }</Submission>
      else
        ()
      }
      <Commands>
        {
        if ($create) then
          <Create Target="c-item-creator">
            <Controller>persons/add?next=redirect</Controller>
            <Label loc="action.add.person">Ajouter une personne</Label>
          </Create>
        else
          (),
        if ($coach) then
          <Save Target="editor" data-src="match/criteria" data-type="json" data-replace-type="event" data-save-flags="disableOnSave silentErrors" onclick="javascript:$('#c-busy').show();$('#c-req-ready').hide();">
            <Label style="min-width: 150px" loc="action.search">Search</Label>
          </Save>
        else
          <Save Target="editor" data-src="persons" data-replace-target="results" data-save-flags="disableOnSave silentErrors" onclick="javascript:$('#c-busy').show()">
            <Label style="min-width: 150px" loc="action.search">Search</Label>
          </Save>
        }
      </Commands>
    </Formular>,
    if ($preview) then
      (: simulates a search targeted at a single person :)
      search:fetch-persons(
        element { $tag }
          {
          <Persons>
            <PersonKey>{$preview}</PersonKey>
          </Persons>
          }
      )
    else
      let $saved-request := submission:get-default-request($tag)
      return
        if (local-name($saved-request) = local-name($submission:empty-req)) then
          <NoRequest/>
        else if ($coach) then
          <RequestReady/>
        else
          search:fetch-persons($saved-request),
    if ($coach) then (
      <Suggest-Filters Target="criteria"/>,
      <Suggest-Results Target="criteria"/>
      )
    else
      (),
    <Modals>
      {
      if ($coach) then
        <Modal Id="c-coach-summary"/>
      else (
        <Modal Id="c-item-viewer" Goal="read">
          <Template>templates/person?goal=read</Template>
          <Commands>
            {
            if (not($coach) and access:check-entity-permissions('delete', 'Person')) then
              <Delete/>
            else
              ()
            }
            <Button Id="c-modify-btn" loc="action.edit"/>
            <Close/>
          </Commands>
        </Modal>,
        <Modal Id="c-item-editor" data-backdrop="static" data-keyboard="false">
          <Template>templates/person?goal=update</Template>
          <Commands>
            <Save/>
            <Cancel/>
          </Commands>
        </Modal>,
        if ($create) then
          <Modal Id="c-item-creator" data-backdrop="static" data-keyboard="false">
            <Name>Add a new person</Name>
            <Template>templates/person?goal=create</Template>
            <Commands>
              <Save/>
              <Cancel/>
              <Clear/>
            </Commands>
          </Modal>
        else
          ()
        )
      }
    </Modals>
    )
};

(: ======================================================================
   Generates plain vanilla person search user interface
   ====================================================================== 
:)
declare function local:gen-person-search-ui ( $cmd as element(), $create as xs:boolean ) as element()* 
{
  <Search skin="search" Initial="true">
    {
    local:gen-search-ui(false(), $create, 'SearchPersonsRequest', 'persons', $cmd/resource/@name)
    }
  </Search>
};

let $cmd := oppidum:get-command()
let $m := request:get-method()
return
  if ($m eq 'POST') then (: executes search requests :)
    let $request := oppidum:get-data()
    return
      <Search>{ search:fetch-persons($request) }</Search>
  else (: shows search page with default results - assumes GET :)
    local:gen-person-search-ui($cmd, access:check-entity-permissions('create', 'Person'))

