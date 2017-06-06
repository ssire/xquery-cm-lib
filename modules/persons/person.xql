xquery version "1.0";
(: --------------------------------------
   Case tracker pilote

   Creation: Stéphane Sire <s.sire@oppidoc.fr>

   CRUD controller to manage Person entries inside the database.

   December 2014 - (c) Copyright 2014 Oppidoc SARL. All Rights Reserved.
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
   Normalizes a string to compare it with another one
   TODO: handle accentuated characters (canonical form ?)
   ======================================================================
:)
declare function local:normalize( $str as xs:string? ) as xs:string {
  upper-case(normalize-space($str))
};

(: ======================================================================
   Checks submitted person data is valid and check the submitted pair.
   Actually does nothing since it seems possible to have homonyms...
   FIXME: check data has a Person root element
   FIXME: maybe we should develop a more advanced protocol with a warning 
   in case FirstName, LastName and Email are identical ?
   Returns a list of error messages or the emtpy sequence if no errors.
   ======================================================================
:)
declare function local:validate-person-submission( $data as element(), $curNo as xs:string? ) as element()* {
  ()
  (:  
  let $key1 := local:normalize($data/Name/LastName/text())
  let $key2 := local:normalize($data/Name/SortString/text())
  let $ckey1 := globals:collection('persons-uri')//Person[local:normalize(Name/LastName) = $key1]
  let $ckey2 := globals:collection('persons-uri')//Person[local:normalize(Name/SortString) = $key2]
  return (
      if ($curNo and empty(globals:collection('persons-uri')//Person[Id = $curNo])) then
        ajax:throw-error('UNKNOWN-PERSON', $curNo)
      else (),
      if ($ckey1) then 
        if (not($curNo) or not($curNo = $ckey1/Id)) then
          ajax:throw-error('PERSON-NAME-CONFLICT', $data/Name/SortString/text())
        else ()
      else (),
      if ($ckey2) then
        if (not($curNo) or ($ckey2/Id != $curNo)) then
          ajax:throw-error('SORTSTRING-CONFLICT', $data/Name/SortString/text())
        else ()
      else ()
      )
  :)
};

(: ======================================================================
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
   Reconstructs a Person record from current Person data and from new submitted
   Person data. Note that current Person may be the empty sequence in case of creation.
   Persists UserProfile element if present.
   ======================================================================
:)
declare function local:gen-person-for-writing( $current as element()?, $new as element(), $index as xs:integer? ) {
  <Person>
    {(
    if ($current) then (
      $current/@PersonId,
      $current/Id 
      )
    else 
      <Id>{$index}</Id>,
    $new/Sex,
    $new/Civility,
    <Name>
      {$new/Name/*}
      {if ($current) then $current/Name/SortString else (<SortString>{$current/Name/LastName}</SortString>)}
    </Name>,
    $new/Country,
    $new/EnterpriseRef,
    $new/Function,
    $new/Contacts,
    $new/Photo,
    local:gen-user-profile-for-writing($current/UserProfile)
    )}
  </Person>
};

(: ======================================================================
   Inserts a new Person inside the database
   TODO: use a Variable to compute Id
   ======================================================================
:)
declare function local:create-person( $cmd as element(), $data as element(), $lang as xs:string ) as element() {
  let $next := request:get-parameter('next', ())
  let $newkey := database:make-new-key-for($cmd/@db, 'person')
  let $person := local:gen-person-for-writing((), $data, $newkey)
  return
    (
    database:create-entity($cmd/@db, 'person', $person),
    if ($next eq 'redirect') then
      ajax:report-success-redirect('ACTION-CREATE-SUCCESS', (), concat($cmd/@base-url, $cmd/@trail, '?preview=', $newkey))
    else (: short ajax protocol with 'augment' or 'autofill' plugin (no table row update) :)
      let $result := 
        <Response Status="success">
          <Payload>
            <Name>{concat($data/Name/FirstName, ' ', $data/Name/LastName)}</Name>
            <Value>{$newkey}</Value>
          </Payload>
        </Response>
      return
        ajax:report-success('ACTION-CREATE-SUCCESS', (), $result)
    )
};

(: ======================================================================
   Updates a Person model into database
   Returns Person model including the update flag (since the user must be allowed)
   ======================================================================
:)
declare function local:update-person( $current as element(), $data as element(), $lang as xs:string ) as element() {
  let $person := local:gen-person-for-writing($current, $data,())
  let $result := search:gen-person-sample($person, (), 'en', true())
  return (
    update replace $current with $person,
    ajax:report-success('ACTION-UPDATE-SUCCESS', (), $result)
    )
};

(: ======================================================================
   Returns a Person model for a given goal
   Note EnterpriseRef -> EnterpriseName for modal window
   ======================================================================
:)
declare function local:gen-person( $person as element(), $lang as xs:string, $goal as xs:string ) as element()* {
  if ($goal = 'read') then
    (: serves both EnterpriseName for the persons/xxx.modal in /stage
       and EnterpriseRef for persons/xxx.blend view in /persons   :)
    let $entname := enterprise:gen-enterprise-name($person/EnterpriseRef, $lang)
    let $roles := 
      <Roles>
      {
      for $r in $person/UserProfile/Roles/Role
      let $services := display:gen-name-for('Services', $r/ServiceRef, $lang)
      return 
        (
        <Function>{ display:gen-name-for('Functions', $r/FunctionRef, $lang) }</Function>,
        if ($services) then 
          <Name>
            { string-join(($services)[. ne ''], ", ") }
          </Name>
        else
          <Name/>
        )
      }
      </Roles>
    return
      <Person>
        { $person/(Id | Sex | Civility | Name | Photo | Contacts) }
        { misc:unreference($person/Country) }
        <EnterpriseRef>{$entname}</EnterpriseRef>
        <EnterpriseName>{$entname}</EnterpriseName>
        {$person/Function}
        { if (count($roles/Function) > 0) then $roles else () }
      </Person>
  else if ($goal = 'update') then
    <Person>
      { $person/(Sex | Civility | Name | Country | EnterpriseRef | Function | Contacts | Photo) }
    </Person>
  else if ($goal = 'autofill') then (: DEPRECATED : Transclusion of ContactPerson :)
    let $payload := 
            (
            <PersonRef>{ $person/Id/text() }</PersonRef>,
            $person/Name,
            $person/(Sex | Civility | Country),
            enterprise:unreference-enterprise($person/EnterpriseRef, 'EnterpriseRef', $lang),
            $person/( Function | Photo | Contacts)
            )
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
          let $data := oppidum:get-data()
          let $errors := local:validate-person-submission($data, $ref)
          return
            if (empty($errors)) then
              if ($creating) then
                util:exclusive-lock(fn:doc(oppidum:path-to-ref())/Persons, local:create-person($cmd, $data, $lang))
              else
                local:update-person($person, $data, $lang)
            else
              ajax:report-validation-errors($errors)
        else
          oppidum:throw-error('FORBIDDEN', ())
    else 
      (: assumes GET, access control done at mapping level :)
      local:gen-person($person, $lang, request:get-parameter('goal', 'read'))
  else 
    oppidum:throw-error("PERSON-NOT-FOUND", ())
