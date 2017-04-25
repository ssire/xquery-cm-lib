xquery version "1.0";
(: --------------------------------------
   XQuery Content Management Library

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Manages a submission controller to save, load or get a default search request
   in relation with the current user.

   Currently there is one submission controller attached to the stage, enterprises
   and persons formulars SearchStageRequest, SearchEnterprisesRequest and SearchPersonsRequest

   May 2013 - (c) Copyright 2013 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

import module namespace request="http://exist-db.org/xquery/request";
import module namespace response = "http://exist-db.org/xquery/response";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace user = "http://oppidoc.com/ns/xcm/user" at "../../lib/user.xqm";
import module namespace submission = "http://oppidoc.com/ns/xcm/submission" at "submission.xqm";

declare option exist:serialize "method=xml media-type=application/xml";

(: ======================================================================
   Save the search request into user's profile if it exists
   PRE-CONDITION: user MUST have write access to the persons resource
   ======================================================================
:)
declare function local:save-default-request ( $request as element() ) {
  let $profile := user:get-user-profile()
  let $found := $profile/*[name(.) = name($request)]
  return
    if ($profile) then
      if ($found) then
        update replace $found with $request
      else
        update insert $request into $profile
    else
      ()
};

(: ======================================================================
   Deletes the search request into user's profile if it exists
   PRE-CONDITION: user MUST have write access to the persons resource
   ======================================================================
:)
declare function local:delete-default-request ( $name as xs:string ) {
  let $profile := user:get-user-profile()
  let $found := $profile/*[name(.) = $name]
  return
    if ($profile) then
      if ($found) then
        update delete $found
      else
        () (: nope :)
    else
      ()
};

(: ======================================================================
   Extract submitted data and check that it contains a request with at least
   one criteria. Saves the request if this is the case, otherwise saves
   the conventional empty request to avoid requesting the full data set 
   by default to save bandwidth.
   ======================================================================
:)
declare function local:do-post () {
  let $request := oppidum:get-data()
  return 
    if ((count($request/*/*) + count($request/*[normalize-space(.) != ''])) = 0) then ( (: empty request :)
      local:delete-default-request(local-name($request)),
      <result status="ok"><message>empty filter saved</message></result>
      )
    else (
      local:save-default-request($request),
      <result status="ok"><message>filter saved</message></result>
    )[last()]
};

let $m := request:get-method()
return
  if ($m eq 'POST') then
    local:do-post()
  else (: assumes GET :)
    let $tmp := request:get-parameter('name', ())
    let $name := if ($tmp) then $tmp else request:get-attribute('xquery.name')
    return
      if ('reset' = request:get-parameter-names()) then
        $submission:empty-req
      else
        (: rewarp the result to avoid Last-Modified header generation - seems to be a bug(feature) of eXist-DB ! :)
        <SearchStageRequest>{ submission:get-default-request($name)/* }</SearchStageRequest>
