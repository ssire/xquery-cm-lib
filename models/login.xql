xquery version "1.0";
(: --------------------------------------
   XQuery Content Management Library

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Either generates the login page model to ask the user to login or tries to login
   the user if credentials are supplied and redirects on success.

   The optional request parameter 'url' contains the full path of a site page
   to redirect the user after a successful login.

   November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)
import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace request = "http://exist-db.org/xquery/request";
import module namespace session = "http://exist-db.org/xquery/session";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../oppidum/lib/util.xqm";

(: ======================================================================
   Generates success response
   ======================================================================
:)
declare function local:gen-success( $user as xs:string ) as element() {
  let $msg := 'ACTION-LOGIN-SUCCESS'
  let $args := $user
  return
    oppidum:add-message($msg, $args, true())
};

(: ======================================================================
   Pre-production stats
   /db/debug/login.xml rwu-wu-wu with root Logs
   Some browsers (Safari) does not validate required attribute hence filters out empty user
   ======================================================================
:)
declare function local:log-action( $outcome as xs:string, $user as xs:string, $ua as xs:string? ) {
  if ($user ne '') then
    let $ts := substring(string(current-dateTime()), 1, 19)
    return
      if (fn:doc-available('/db/debug/login.xml')) then
        update insert <Login User="{$user}" TS="{$ts}" UA="{$ua}">{$outcome}</Login> into fn:doc('/db/debug/login.xml')/Logs
      else
        ()
  else
    ()
};

(: ======================================================================
   Adds a warning message in dev or test mode using either an error
   or a message (note: use a message if you need AXEL to be loaded see skin.xml)
   ====================================================================== 
:)
declare function local:warn( $cmd as element(), $err as xs:boolean ) {
  let $warn := 
    if ($cmd/@mode eq 'test') then
      'MODE-WARNING-TEST'
    else if ($cmd/@mode eq 'dev') then
      'MODE-WARNING-DEV'
    else
      ()
  return
    if ($warn) then
      if ($err) then
        oppidum:add-error($warn, (), true())
      else
        oppidum:add-message($warn, (), true())
    else
      ()
};

(: ======================================================================
   Returns true() in case current time is within [$sd, $sd + $duration]
   temporal window as defined on the Logs element of the optional login.xml
   resource as [@Shutdown, @Shutdown + @Duration]
   ====================================================================== 
:)
declare function local:shutdown( $sd as xs:string, $duration as xs:string ) as xs:boolean {
  let $date-time := string(current-dateTime())
  let $date := current-date()
  let $shutdown-ts := concat(substring-before(string($date), '+'),'T', $sd, ':00.000+', substring-after(string($date), '+'))
  let $after-ts := string(xs:dateTime($shutdown-ts) + xs:dayTimeDuration(concat("PT",substring-before($duration,':'),"H",substring-after($duration,':'),"M")))
  return $date-time gt $shutdown-ts and $date-time lt $after-ts
};

(: ======================================================================
   Rewrites the Goto URL to absolute path using command's base URL
   This way the redirection is independent from the reverse proxy in prod or test
   ======================================================================
:)
declare function local:rewrite-goto-url ( $cmd as element(), $url as xs:string? ) as xs:string {
  let $startref := fn:doc(oppidum:path-to-config('mapping.xml'))/site/@startref
  return
    if ($url and (substring-after($url, $cmd/@base-url) ne $startref)) then
      if (not(starts-with($url, '/'))) then
        concat($cmd/@base-url, $url)
      else 
        $url
    else (: overwrites startref redirection or no explicit redirection parameter :)
      let $goto := fn:doc(oppidum:path-to-config('settings.xml'))/Settings/Module[Name eq 'login']/Property[Key eq 'startref']
      return
        if ($goto) then
          concat($cmd/@base-url, $goto/Value)
        else
          concat($cmd/@base-url, $startref)
};

let $cmd := request:get-attribute('oppidum.command')
let $user := request:get-parameter('user', '')
let $goto-url := local:rewrite-goto-url($cmd, request:get-parameter('url', ()))
let $m := request:get-method()
let $ua := request:get-header('user-agent')
let $uua := upper-case($ua)
let $ie := contains($uua, 'MSIE') or contains($uua, "TRIDENT") (: since IE 11:) or contains($uua, "EDGE") (: since Windows 10 :)
let $this := local:rewrite-goto-url($cmd, 'login')
return
    <Login>
      {
      if ($ie) then (: TEMPORARY oppidum:add-message('BROWSER-WARNING', (), false()):)
        (
        local:log-action('ie', $user, $ua),
        oppidum:add-error('BROWSER-WARNING', ($ua), true())
        )
      else
        let $shutdown := fn:doc('/db/debug/login.xml')/Logs/@Shutdown
        let $duration := fn:doc('/db/debug/login.xml')/Logs/@Duration
        let $hold := fn:doc('/db/debug/login.xml')/Logs/@Hold
        return
          if (not(empty($hold)) and ($user ne string($hold))) then
            (
            oppidum:add-error('HOLD', (), true()),
            <Hold/>
            )
          else if (not(empty($shutdown) or empty($duration)) and local:shutdown($shutdown, $duration)) then
            (
            let $sd := concat( $shutdown, ':00')
            let $readable-end := string(xs:time($sd) + xs:dayTimeDuration(concat("PT",substring-before($duration,':'),"H",substring-after($duration,':'),"M")))
            return oppidum:add-error('SHUTDOWN', ($sd, $readable-end), true())
            )
          else if ($m = 'POST') then
            (: tries to login, ask oppidum to redirect on success :)
            let $password := request:get-parameter('password', '')
            return
              if (xdb:login('/db', $user, $password, true())) then
                (
                local:log-action('success', $user, $ua),
                local:warn($cmd, false()),
                local:gen-success($user),
                oppidum:redirect($goto-url),
                <Redirected>{$goto-url}</Redirected>
                )
              else (: login page model, asks again, keeps user because wrong password in most cases :)
                (
                local:log-action('failure', $user, $ua),
                local:warn($cmd, true()),
                oppidum:add-error('ACTION-LOGIN-FAILED', (), true())
                )
          else
            local:warn($cmd, true()),
      <User>{ if (($user != '') and xdb:exists-user($user)) then $user else () }</User>,
      <To>{ $goto-url }</To>
      }
    </Login>

