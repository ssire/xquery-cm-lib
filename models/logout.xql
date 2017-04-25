xquery version "1.0";
(: --------------------------------------
   XQuery Content Management Library

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Logout user from database and session.

   The request parameter 'url' contains the full path of a site page
   to redirect the user after a successful login.

   WARNING: directly calls response:redirect-to() so it must be used in a
   pipeline with no view and no epilogue !

   November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)
import module namespace request = "http://exist-db.org/xquery/request";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace response = "http://exist-db.org/xquery/response";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../lib/globals.xqm";

let $cmd := request:get-attribute('oppidum.command')
let $goto-url := request:get-parameter('url', $cmd/@base-url)
let $log-user := if (globals:doc('log-file-uri')/Logs/@Hold[. ne '']) then oppidum:get-current-user() else ()
return
  <Redirected>
    {
    xdb:login("/db", "guest", "guest"),
    (: do not forget to call session:invalidate() in a second time
       in the epilogue as add-message may use the session :)
    oppidum:add-message('ACTION-LOGOUT-SUCCESS', (), true()),
    response:redirect-to(xs:anyURI($goto-url)),
    (: records logout to help maintenance :)
    if ($log-user) then
      let $ts := substring(string(current-dateTime()), 1, 19)
      return
        update insert <Logout User="{$log-user}" TS="{$ts}"/> into globals:doc('log-file-uri')/Logs
    else
      ()
    }
  </Redirected>
