xquery version "1.0";
(: --------------------------------------
   Case tracker pilote

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Controller to delete an Enterprise.

   November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)
import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace request="http://exist-db.org/xquery/request";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../../lib/globals.xqm";
import module namespace access = "http://oppidoc.com/ns/xcm/access" at "../../lib/access.xqm";
import module namespace ajax = "http://oppidoc.com/ns/xcm/ajax" at "../../lib/ajax.xqm";
import module namespace cache = "http://oppidoc.com/ns/xcm/cache" at "../../lib/cache.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

(: ======================================================================
   Checks that deleting $enterprise is compatible with current DB state :
   - not linked to a Case (as ClientEnterprise)
   - not linked to a Person (as EnterpriseRef except in a saved search request)
   WARNING: those rules do not prevent to delete an Enterprise while someone else is performing
   an action that could reference that enterprise (wiki lost copy dilmena) but this should be rare
   ======================================================================
:)
declare function local:validate-enterprise-delete( $id as xs:string ) as element()* {
  let $case := globals:collection('cases-uri')//EnterpriseRef[. = $id][1]/ancestor::Case/Information/Acronym/text()
  let $person := globals:collection('persons-uri')//Person[EnterpriseRef = $id][1]/Name
  return
    let $err1 := if (empty($case)) then () else ajax:throw-error('ENTERPRISE-LINKED-TO-CASE', $case)
    let $err2 := if (empty($person)) then () else ajax:throw-error('ENTERPRISE-LINKED-TO-PERSON', concat($person/FirstName, " ", $person/LastName))
    let $errors := ($err1, $err2)
    return
      if (count($errors) > 0) then
        let $explain :=
          string-join(
            for $e in $errors
            return $e/message/text(), ' ')
        return
          oppidum:throw-error('DELETE-ENTERPRISE-FORBIDDEN', $explain)
      else
        ()
};

(: ======================================================================
   Delete the enterprise targeted by the request
   NOTE: currently if the last enterprise is deleted, the next enterprise
   that will be created will get the same Id since we do not memorize a LastIndex
   ======================================================================
:)
declare function local:delete-enterprise( $enterprise as element(), $lang as xs:string ) as element()* {
  (: copy id and name to a new string to avoid loosing once deleted :)
  let $result :=
    <Response Status="success">
      <Payload Table="Enterprise">
        <Value>{string($enterprise/Id)}</Value>
      </Payload>
    </Response>
  let $name := string($enterprise/Name)
  return (
    update delete $enterprise,
    cache:invalidate('enterprise', $lang),
    cache:invalidate('town', $lang),
    ajax:report-success('DELETE-ENTERPRISE-SUCCESS', $name, $result)
    )
};

let $m := request:get-method()
let $cmd := oppidum:get-command()
let $enterprise-uri := oppidum:path-to-ref()
let $id := tokenize($cmd/@trail,'/')[2]
let $enterprise := fn:doc($enterprise-uri)/Enterprises/Enterprise[Id = $id]
let $lang := string($cmd/@lang)
return
  if ($enterprise) then (: sanity check :)
    if (access:check-entity-permissions('delete', 'Enterprise', $enterprise)) then (: 1st check : authorized user ? :)
      let $errors := local:validate-enterprise-delete($id)  (: 2nd: compatible database state ? :)
      return
        if (empty($errors)) then
          if ($m = 'DELETE' or (($m = 'POST') and (request:get-parameter('_delete', ()) eq "1"))) then (: real delete  :)
            local:delete-enterprise($enterprise, $lang)
          else if ($m = 'POST') then (: delete pre-step - we use POST to avoid forgery - :)
            ajax:report-success('DELETE-ENTERPRISE-CONFIRM', $enterprise/Name/text())
          else
            ajax:throw-error('URI-NOT-SUPPORTED', ())
        else
          $errors
    else
      ajax:throw-error('FORBIDDEN', ())
  else
    ajax:throw-error('URI-NOT-SUPPORTED', ())

