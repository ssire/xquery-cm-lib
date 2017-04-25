xquery version "1.0";
(: --------------------------------------
   Case tracker pilote

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Returns recent login

   Trick: use ?full to get User-Agent string

   February 2015 - (c) Copyright 2015 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

import module namespace request="http://exist-db.org/xquery/request";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

declare function local:gen-login-log ( $date as xs:string, $tag as xs:string, $resource as xs:string ) as element() {
  element { $tag } { 
    let $count := count(distinct-values(fn:doc('/db/debug/login.xml')//Login[starts-with(@TS, $date)][. eq 'success']/@User))
    return
      attribute { 'UniCount' } { $count },
      for $l in fn:doc('/db/debug/login.xml')//(Login[starts-with(@TS, $date)][(@User ne '') and (. = ('success', 'ie') or (. = 'failure' and $resource = 'access'))] | Hold[starts-with(@TS, $date)] | Logout[starts-with(@TS, $date)])
      order by $l/@TS descending
      return $l
  }
};

declare function local:gen-login-log-all( $tag as xs:string, $resource as xs:string ) as element() {
  element { $tag } {
    let $logins := fn:doc('/db/debug/login.xml')//(Login[(@User ne '') and (. = ('success', 'ie') or (. = 'failure' and $resource = 'access'))] | Hold | Logout)
    let $count := count($logins)
    return
    (
      attribute { 'UniCount' } { $count },
      attribute { 'Days' } { days-from-duration(xs:dateTime($logins[last()]/@TS) - xs:dateTime($logins[1]/@TS)) }, 
      for $l in fn:doc('/db/debug/login.xml')//(Login[(@User ne '') and (. = ('success', 'ie') or (. = 'failure' and $resource = 'access'))] | Hold | Logout)
      order by substring($l/@TS,12,2) descending
      return $l
    )
  }
};

let $cmd := oppidum:get-command()
let $today := substring(string(current-date()), 1, 10)
let $yesterday := substring(string(current-date() - xs:dayTimeDuration("P1D")), 1, 10)
let $time := substring(string(current-time()), 1, 5)
let $full := request:get-parameter-names() = 'full'
return
  <Logs Time="{$time}">
    { 
    if ($full) then attribute Full { 'on' } else (),
    fn:doc('/db/debug/login.xml')/Logs/@Shutdown,
    fn:doc('/db/debug/login.xml')/Logs/@Duration,
    local:gen-login-log($today, 'Today', $cmd/resource/@name),
    local:gen-login-log($yesterday, 'Yesterday', $cmd/resource/@name),
    if ($cmd/resource/@name = 'access') then
      local:gen-login-log-all('All', $cmd/resource/@name)
    else
      ()
    }
    <!--{ 
      if ($cmd/resource/@name = 'access') then
        local:gen-login-log-notin(($today, $yesterday), 'Others', $cmd/resource/@name)
      else
        ()
    }-->
  </Logs>
