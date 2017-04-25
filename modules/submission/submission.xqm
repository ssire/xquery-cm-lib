xquery version "1.0";
(: --------------------------------------
   XQuery Content Management Library

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Shared methods to access user's submission entity

   June 2013 - (c) Copyright 2013 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

module namespace submission = "http://oppidoc.com/ns/xcm/submission";

import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace user = "http://oppidoc.com/ns/xcm/user" at "../../lib/user.xqm";

declare variable $submission:empty-req := <Request/>;

(: ======================================================================
   Returns the saved search request from the user's profile if it exists
   or a conventional empty request otherwise
   $name is the name of the element storing the request in UserProfile
   ======================================================================
:)
declare function submission:get-default-request ( $name as xs:string ) as element() {
  let $profile := user:get-user-profile()
  let $found := $profile/*[name(.) = $name]
  return
    if ($found) then
      $found
    else
      $submission:empty-req
};
