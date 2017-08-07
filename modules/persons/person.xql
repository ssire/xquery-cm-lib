xquery version "1.0";
(: --------------------------------------
   XQuery Content Management Library

   CRUD controller to manage Person entities inside the database

   This is a sample file for Case Tracker Pilote

   You MOST probably will need to copy this file to your 
   project to customize it to fit your application data model

   Creation: Stéphane Sire <s.sire@oppidoc.fr>

   August 2017 - (c) Copyright 2017 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

import module namespace request="http://exist-db.org/xquery/request";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../../lib/globals.xqm";
import module namespace display = "http://oppidoc.com/ns/xcm/display" at "../../lib/display.xqm";
import module namespace access = "http://oppidoc.com/ns/xcm/access" at "../../lib/access.xqm";
import module namespace user = "http://oppidoc.com/ns/xcm/user" at "../../lib/user.xqm";
import module namespace ajax = "http://oppidoc.com/ns/xcm/ajax" at "../../lib/ajax.xqm";
import module namespace misc = "http://oppidoc.com/ns/xcm/misc" at "../../lib/util.xqm";
import module namespace database = "http://oppidoc.com/ns/xcm/database" at "../../lib/database.xqm";
import module namespace enterprise = "http://oppidoc.com/ns/xcm/enterprise" at "../enterprises/enterprise.xqm";

import module namespace search = "http://oppidoc.com/ns/xcm/search" at "search.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

(: ======================================================================
   Checks submitted person data is valid and check the submitted pair.
   Actually does nothing since it seems possible to have homonyms...
   Returns a list of error messages or the emtpy sequence if no errors.

   TODO: implement with validate data template
   ======================================================================
:)
declare function local:validate-person-submission( $submitted as element(), $curNo as xs:string? ) as element() {
  <success/>
  (:  
  let $key1 := local:normalize($submitted/Name/LastName/text())
  let $key2 := local:normalize($submitted/Name/SortString/text())
  let $ckey1 := globals:collection('persons-uri')//Person[local:normalize(Information/Name/LastName) = $key1]
  let $ckey2 := globals:collection('persons-uri')//Person[local:normalize(Information/Name/SortString) = $key2]
  return (
      if ($curNo and empty(globals:collection('persons-uri')//Person[Id = $curNo])) then
        ajax:throw-error('UNKNOWN-PERSON', $curNo)
      else (),
      if ($ckey1) then 
        if (not($curNo) or not($curNo = $ckey1/Id)) then
          ajax:throw-error('PERSON-NAME-CONFLICT', $submitted/Name/SortString/text())
        else ()
      else (),
      if ($ckey2) then
        if (not($curNo) or ($ckey2/Id != $curNo)) then
          ajax:throw-error('SORTSTRING-CONFLICT', $submitted/Name/SortString/text())
        else ()
      else ()
      )
  :)
};

(: ======================================================================
   Inserts a new Person inside the database using person's create data template
   and data mapping configuration in database.xml
   ======================================================================
:)
declare function local:create-person( $cmd as element(), $submitted as element(), $lang as xs:string ) as element() {
  let $next := request:get-parameter('next', ())
  let $created := template:do-create-resource('person', (), (), $submitted, ())
  return
    if ($created eq 'success') then
      if ($next eq 'redirect') then
        ajax:report-success-redirect('ACTION-CREATE-SUCCESS', (), concat($cmd/@base-url, $cmd/@trail, '?preview=', $created))
      else (: short ajax protocol with 'augment' or 'autofill' plugin (no table row update) :)
        let $result := 
          <Response Status="success">
            <Payload>
              <Name>{ concat($submitted/Name/FirstName, ' ', $submitted/Name/LastName) }</Name>
              <Value>{ $created/text() }</Value>
            </Payload>
          </Response>
        return
          ajax:report-success('ACTION-CREATE-SUCCESS', (), $result)
      )
    else
      $created
};

(: ======================================================================
   DEPRECATED

   Regenerates the UserProfile for the current submitted person wether s/he exists or not
   Interprets current request "f" parameter to assign "kam" or "coach" function on the fly
   FIXME: 
   - access control layer before promoting a kam or coach ?
   - ServiceRef and / or RegionalEntityRef should be upgraded on workflow transitions
   ======================================================================
:)
declare function local:gen-user-profile-for-writing( $profile as element()? ) {
  let $function := request:get-parameter("f", ())
  let $fref := user:get-function-ref-for-role($function)
  return
    if ($fref and ($function = ('kam', 'coach'))) then
      if ($profile) then 
        if ($profile/Roles/Role/FunctionRef[. eq $fref]) then (: simple persistence :)
          $profile
        else
          <UserProfile>
            <Roles>
              { $profile/Roles/Role }
              <Role><FunctionRef>{ $fref }</FunctionRef></Role>
            </Roles>
          </UserProfile>
      else
          <UserProfile>
            <Roles>
              <Role><FunctionRef>{ $fref }</FunctionRef></Role></Roles>
          </UserProfile>
    else (: simple persistence :)
      $profile
};



(: ======================================================================
   Updates a Person model into database

   TODO:
   - reintegrate local:gen-user-profile-for-writing($current/UserProfile)
   - test if updating from search (XSLT pipeline) or from augment command (Name / Value protocol)
   ======================================================================
:)
declare function local:update-person( $person as element(), $submitted as element(), $lang as xs:string ) as element() {
  let $id := string($person/Id)
  let $updated := template:do-update-resource('person', $id, $person, (), $submitted)
  return
    if ($updated eq 'success') then
      ajax:report-success('ACTION-UPDATE-SUCCESS', (), 
        if (request:get-parameter('next', ()) eq 'autofill') then
          <Response Status="success">
            <Payload Table="Person">
              <Name>{ concat($submitted/Name/FirstName, ' ', $submitted/Name/LastName) }</Name>
              <Value>{ $id) }</Value>
            </Payload>
          </Response>
        else (: maybe we could use $person this is to be sure to get updated data :)
          let $fresh-person := globals:collection('persons-uri')//Person[Id eq $id]
          return search:gen-person-sample($fresh-person, (), true(), 'en')
      )
    else
      $updated
};

(: ======================================================================
   Returns a Person model for a given goal
   Note EnterpriseKey -> EnterpriseName for modal window
   ======================================================================
:)
declare function local:gen-person( $person as element(), $goal as xs:string, $lang as xs:string ) as element()* {
  if ($goal = 'read') then
    template:gen-read-model('person-with-roles', $person, $lang)
  else if ($goal = 'update') then
    template:gen-read-model('person', $person, $lang)
  else if ($goal = 'autofill') then (: refresh a Person transclusion inside a formular  :)
    let $payload := template:gen-transclusion('person', $person/Id, $person)
    let $envelope := request:get-parameter('envelope', '')
    return
      <data>
        {
        if ($envelope) then
          element { $envelope } { $payload }
        else
          $payload
        }
      </data>
  else
    ()
};

(: *** MAIN ENTRY POINT *** :)
let $m := request:get-method()
let $cmd := oppidum:get-command()
let $lang := string($cmd/@lang)
let $creating := ($m eq 'POST') and ($cmd/@action eq 'add')
let $ref := if ($cmd/@action eq 'add') then () else string($cmd/resource/@name)
let $person := if ($ref) then fn:doc(oppidum:path-to-ref())/Persons/Person[Id = $ref] else ()
return
  if ($creating or $person) then
    if ($m = 'POST') then
      let $allowed := 
        if ($creating) then
          access:check-entity-permissions('create', 'Person')
        else 
          access:check-entity-permissions('update', 'Person', $person)
      return
        if ($allowed) then
          let $submitted := oppidum:get-data()
          let $validated := <success/> (: local:validate-person-submission($submitted, $ref) :)
          return
            if (local-name($validated) eq 'success') then
              if ($creating) then
                util:exclusive-lock(fn:doc(oppidum:path-to-ref())/Persons, local:create-person($cmd, $submitted, $lang))
              else
                local:update-person($person, $submitted, $lang)
            else
              ajax:report-validation-errors($validated)
        else
          oppidum:throw-error('FORBIDDEN', ())
    else 
      (: assumes GET, access control done at mapping level :)
      local:gen-person($person, request:get-parameter('goal', 'read'), $lang)
  else 
    oppidum:throw-error("PERSON-NOT-FOUND", ())
