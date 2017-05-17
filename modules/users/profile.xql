xquery version "1.0";
(: --------------------------------------
   XQuery Content Management Library

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   CRUD controller to manage user's role in his UserProfile section

   April 2014 - (c) Copyright 2014 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

import module namespace sm = "http://exist-db.org/xquery/securitymanager";
import module namespace util="http://exist-db.org/xquery/util";
import module namespace request="http://exist-db.org/xquery/request";

import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../../lib/globals.xqm";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace ajax = "http://oppidoc.com/ns/xcm/ajax" at "../../lib/ajax.xqm";
import module namespace account = "http://oppidoc.com/ns/xcm/account" at "account.xqm";
import module namespace display = "http://oppidoc.com/ns/xcm/display" at "../../lib/display.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

(: ======================================================================
   Checks submitted data is correct :
   - no empty role definition (note that since FunctionRef is mandatory this is redundant with client side validation)
   - no duplicated role definition
   - does not accept to remove Service responsible role
     since the correct way is to designate a new person with the role ("no vacancy" integrity constraint)
   - check a Service responsible has a ServiceRef
   - check a RegionalEntity director has a RegionalEntityRef
   - check a Coach has at least a ServiceRef
   FIXME: we could also implements rules such as ServiceRef for coaches or CantonnalAntennaRef for director
   Returns an error or the empty sequence
   ======================================================================
:)
declare function local:validate-profile-submission( $person as element(), $data as item()?, $uname as xs:string ) as element()* {
  if (not($data instance of element())) then
    ajax:throw-error('VALIDATION-FORMAT-ERROR', ())
  else if (local-name($data) ne 'UserProfile') then
    ajax:throw-error('VALIDATION-ROOT-ERROR', local-name($data))
  else if ($data/Roles/Role[not(FunctionRef)] or $data/Roles/Role/FunctionRef[. eq '']) then
    ajax:throw-error('VALIDATION-PROFILE-FAILED', local-name($data))
  else if (count(distinct-values($data/Roles/Role/FunctionRef)) ne count($data/Roles/Role/FunctionRef)) then
    ajax:throw-error('VALIDATION-DUPLICATED-ROLE', ())
  else (: an admin-system cannot remove the Administration role from herself :)
    if (normalize-space($uname) eq oppidum:get-current-user()) then 
      if ($data/Roles/Role/FunctionRef[.='1']) then (: FIXME: hard coded reference :)
        ()
      else
        ajax:throw-error('PROTECT-ADMIN-SYSTEM-ROLE', ())
    else
      ()
};

(: ======================================================================
   Returns Ajax protocol to update roles column in user management table
   ====================================================================== 
:)
declare function local:make-ajax-response( $key as xs:string, $roles as element()?, $contact as xs:string?, $id as xs:string ) {
  <Response Status="success">
    <Payload Key="{$key}">
      <Name>{ display:gen-roles-for($roles, 'en') }</Name>
      <Contact>{ $contact }</Contact>
      <Value>{ $id }</Value>
    </Payload>
  </Response>
};

(: ======================================================================
   SynchronizeS A Person eXist-DB groups with his/her UserProfile groups
   Does nothing if the Person hasn't got a Username nor an eXist-DB login
   Ajax response contains a payload with a Key attribute to close modal windows (see management.js)
   ======================================================================
:)
declare function local:synch-user-groups( $person as element() ) {
  let $login := string($person//Username)
  let $uname := concat($person/Name/FirstName, ' ', $person/Name/LastName)
  let $results := local:make-ajax-response('profile', $person/UserProfile/Roles, (), $person/Id)
  return
    if ($login and sm:user-exists($login)) then
      let $has := sm:get-user-groups($login)
      let $should := account:gen-groups-for-user($person)
      return 
        (
        if ( (every $x in $has satisfies $x = $should) and (every $y in $should satisfies $y = $has) ) then
          ()
        else
          system:as-user(account:get-secret-user(), account:get-secret-password(), account:set-user-groups($login, $should)),
        let $msg := concat($uname, " (", string-join($should, ", "), ")")
        return
          ajax:report-success('PROFILE-UPDATED', $msg, $results)
        )
    else
      ajax:report-success('PROFILE-UPDATED-WOACCESS', $uname, $results)
};

(: ======================================================================
   Guaranties that Person with $id will be the only one to have a role $func-ref
   by deleting the same Role from any other Person's UserProfile
   ======================================================================
:)
declare function local:enforce-uniqueness ( $id as xs:string, $func-ref as xs:string , $serv-ref as xs:string?, $ca-ref as xs:string?) {
  for $p in globals:doc('persons-uri')//Person[UserProfile/Roles/Role/FunctionRef[. = $func-ref]][Id ne $id]
  let $role := $p/UserProfile/Roles/Role[FunctionRef = $func-ref]
  where ($serv-ref and ($role/ServiceRef = $serv-ref)) or ($ca-ref and ($role/RegionalEntityRef = $ca-ref) )
  return
    update delete $role
};

(: ======================================================================
   Updates a Profile model into database with $data submitted from the profile.xml formular
   ======================================================================
:)
declare function local:update-profile( $person as element(), $data as element(), $synch as xs:boolean ) as element()* {
  let $profile := $person/UserProfile
  let $done := 
    if ($profile) then (: update :)
      (
      (: 1. updates or deletes Roles :)
      if ($data/Roles) then
        if ($profile/Roles) then 
          update replace $profile/Roles with $data/Roles
        else
          update insert $data/Roles into $profile
      else
        if ($profile/Roles) then update delete $profile/Roles else ()
      )
    else (: creation  :)
      let $profile :=  
        <UserProfile>
        {
        $data/Roles
        }
        </UserProfile>
      return
        update insert $profile into $person
  return
    (
    if ($data//FunctionRef[. eq '12']/../ProjectId) then
     (if ($person/@PersonId) then
        update value $person/@PersonId with $data//FunctionRef[. eq '12']/../ProjectId/text()
      else
        update insert attribute PersonId { $data//FunctionRef[. eq '12']/../ProjectId/text() } into $person,
      update delete $profile//ProjectId)
    else
      (),
    (: FIXME: 1 EASME Head of Service per Service ? :)
    (: 1 Regional Entity Manager per Entity ? :)
    (: if ($data/Roles/Role/FunctionRef[. eq '3']) then 
      local:enforce-uniqueness(string($person/Id), '3', (), $data/Roles/Role[FunctionRef[. eq '3']]/RegionalEntityRef)
    else
      (),:)
    if ($synch) then
      local:synch-user-groups($person)
    else (: remote user :)
      (    
      let $results := local:make-ajax-response('remote', $person/UserProfile/Roles, $data/Contacts/Email/text(), $person/Key/text())
      let $should := account:gen-groups-for-user($person)
      return 
        (
        let $msg := concat($person/Key/text(), " (", string-join($should, ", "), ")")
        return
          ajax:report-success('PROFILE-UPDATED', $msg, $results)
        ),
      update value $person/Key with $data/Contacts/Email/text()
      )
    )
};

(: ======================================================================
   Generates profile model to edit with profile.xml formular 
   ======================================================================
:)
declare function local:gen-profile-for-editing( $id as xs:string, $lang as xs:string ) as element()* {
  let $p := fn:doc(oppidum:path-to-ref())/Persons/Person[Id = $id]
  return
    if (empty($p) or empty($p/UserProfile) or empty($p/UserProfile/Roles) or empty($p/UserProfile/Roles/Role)) then
      (: safeguard to avoid AXEL infinite loop in xt:repeat on <Roles/> :)
      <UserProfile/>
    else 
      <UserProfile>
        { if (empty($p)) then <Contacts><Email>{ $id }</Email></Contacts> else ()},
        <Roles>
        {
          for $r in $p/UserProfile/Roles/Role
          return
            if ($r/FunctionRef/text() eq '12') then
              <Role>{ $r/*, <ProjectId>{ string($p/@PersonId) }</ProjectId> }</Role>
            else
              $r
        }
        </Roles>
      </UserProfile>
};

let $m := request:get-method()
let $cmd := oppidum:get-command()
let $id := util:unescape-uri(string($cmd/resource/@name), 'UTF-8')
let $lang := string($cmd/@lang)
return
  if ($m = 'POST') then
    let $data := oppidum:get-data()
    let $person := fn:doc(oppidum:path-to-ref())/Persons/Person[Id = $id]
    let $uname := string($person/UserProfile/Username)
    return
      let $errors := local:validate-profile-submission($person, $data, $uname)
      return
        if (empty($errors)) then
          if ($person) then
            local:update-profile($person, $data, true())
          else
            ajax:throw-error('URI-NOT-SUPPORTED', ())
        else
          $errors
  else (: assumes GET :)
    local:gen-profile-for-editing($id, $lang)
