xquery version "1.0";
(: --------------------------------------
   XQuery Content Management Library

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   User password management
   Manages requests to generate a new password or to change user's password

   March 2014 - (c) Copyright 2014 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

declare namespace xdb = "http://exist-db.org/xquery/xmldb";

import module namespace request="http://exist-db.org/xquery/request";
import module namespace sm = "http://exist-db.org/xquery/securitymanager";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace ajax = "http://oppidoc.com/ns/xcm/ajax" at "../../lib/ajax.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../../lib/globals.xqm";
import module namespace account = "http://oppidoc.com/ns/xcm/account" at "account.xqm";

declare option exist:serialize "method=xml media-type=application/xml";

(: ======================================================================
   Checks submitted password is hard enough
   ======================================================================
:)
declare function local:validate-password-submission( $password as xs:string ) as xs:boolean {
  if (string-length($password) >= 8) then
    true()
  else (
    ajax:throw-error('ACCOUNT-MALFORMED-PWD', ()),
    false()
    )[last()]
};

(: ======================================================================
   Checks user can proceed to ask for automatic generation of a new password
   ======================================================================
:)
declare function local:validate-user( $login as xs:string, $mail as xs:string ) as element() {
  let $user := globals:collection('persons-uri')//Person[UserProfile/Username = normalize-space($login)]
  return
    if (($login ne '') and ($mail ne '')) then
      if ($user) then
        if ($user/Information/Contacts/Email) then
          if ($user/Information/Contacts/Email/text() = normalize-space($mail)) then
            $user
          else
            ajax:throw-error('VALIDATION-WRONG-EMAIL', $mail)
        else
          ajax:throw-error('VALIDATION-NO-EMAIL', $login)
      else
        ajax:throw-error('VALIDATION-NO-PROFILE', $login)
    else
      ajax:throw-error('MISSING-FIELDS', ())
};

(: ======================================================================
   Generates view model to generate the form to ask for a new password
   ======================================================================
:)
declare function local:gen-ask-pwd-model( $user as element() ) {
  <AskUserPassword>
    <Controller>me</Controller>
    { $user/UserProfile/Username }
    <Name>{ concat($user/Name/FirstName, " ",  $user/Name/LastName) }</Name>
  </AskUserPassword>
};

(: ======================================================================
   Generates a new password for the user, send it by email then change the user password in the database.
   ======================================================================
:)
declare function local:gen-new-password( $user as element() ) {
  let $to := $user/Information/Contacts/Email/text()
  let $new-pwd := account:gen-password($user/UserProfile/Username, $to)
  return (
    if (account:send-new-password($user, $new-pwd, $to, true())) then (
      system:as-user(account:get-secret-user(), account:get-secret-password(), sm:passwd($user/UserProfile/Username, $new-pwd)),
      (: redirect in POST does not seem to work hence we generate a page content :)
      (:        ajax:report-success-redirect('NEW-PASSWORD-SENT', $to, $redirect):)
      <New>
        <Email>{$to}</Email>
      </New>
      )
    else (
      ajax:throw-error('SEND-PASSWORD-FAILURE', $to),
      <AskUserHint>
        <Controller>forgotten</Controller>
      </AskUserHint>
      )
    )
};

(: ======================================================================
   Updates the user password
   ======================================================================
:)
declare function local:change-password( $user as element() ) {
  let $to := $user/Information/Contacts/Email/text()
  let $change := normalize-space(request:get-parameter('change', ()))
  let $check := normalize-space(request:get-parameter('check', ()))
  return
    if ($change and $check and ($change eq $check)) then
      if (local:validate-password-submission($change)) then (
        system:as-user(account:get-secret-user(), account:get-secret-password(), sm:passwd($user/UserProfile/Username, $change)),
        <Changed/>
        )
      else
        local:gen-ask-pwd-model($user)
    else (
      ajax:throw-error('ACCOUNT-INCONSISTENT-PWD', ()),
      local:gen-ask-pwd-model($user)
      )
};

let $m := request:get-method()
let $cmd := oppidum:get-command()
return
    <Display>
    {
    if ($cmd/@action = 'forgotten') then (: tunnel to generate a new password :)
      if ($m eq 'GET') then
        <AskUserHint>
          <Controller>forgotten</Controller>
        </AskUserHint>
      else if ($m eq 'POST') then
        let $uid := request:get-parameter('user', '')
        let $mail := request:get-parameter('mail', '')
        let $user := local:validate-user($uid, $mail)
        return
          if (local-name($user) eq 'Person') then
            local:gen-new-password($user)
          else
            <AskUserHint>
              <Controller>forgotten</Controller>
            </AskUserHint>
      else
        ajax:throw-error('URI-NOT-SUPPORTED', ())
    else if ($cmd/resource/@name = 'me') then (: tunnel to change password :)
      let $user := globals:collection('persons-uri')//Person[UserProfile/Username = xdb:get-current-user()]
      return
        if ($user) then
          if ($m eq 'GET') then
            local:gen-ask-pwd-model($user)
          else if ($m eq 'POST') then
            local:change-password($user)
          else
            ajax:throw-error('URI-NOT-SUPPORTED', ())
        else
          ajax:throw-error('FORBIDDEN', ())
    else
      ajax:throw-error('URI-NOT-SUPPORTED', ())
    }
    </Display>
