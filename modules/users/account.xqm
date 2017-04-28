xquery version "1.0";
(: --------------------------------------
   XQuery Content Management Library

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Utility functions to manage user's accounts

   April 2014 - (c) Copyright 2014 Oppidoc SARL. All Rights Reserved. 
   ------------------------------------------------------------------ :)

module namespace account = "http://oppidoc.com/ns/xcm/account";

import module namespace sm = "http://exist-db.org/xquery/securitymanager";

import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../../lib/globals.xqm";
import module namespace user = "http://oppidoc.com/ns/xcm/user" at "../../lib/user.xqm";
import module namespace form = "http://oppidoc.com/ns/xcm/form" at "../../lib/form.xqm";
import module namespace media = "http://oppidoc.com/ns/xcm/media" at "../../lib/media.xqm";

(: we need a DBA user to create / change user's login inside databse :)
(: TODO: store into settings.xml instead :)
declare variable $account:usecret := 'admin';
declare variable $account:psecret := 'foo';

(: ======================================================================
   Sets eXist-DB groups of user
   ====================================================================== 
:)
declare function account:set-user-groups( $login as xs:string, $groups as xs:string* ) {
  let $has := if (sm:user-exists(string($login))) then sm:get-user-groups(string($login)) else ()
  return (
    for $gp in $has
    where not($gp = $groups)
    return sm:remove-group-member($gp, $login),
    for $gp in $groups
    where not($gp = $has)
    return (
      if (not(sm:group-exists($gp))) then sm:create-group($gp) else (),
      sm:add-group-member($gp, $login)
      )
    )
};

(: ======================================================================
   Utility to return variables representing current user name
   ======================================================================
:)
declare function local:gen-user-name( $prefix as xs:string, $ref as xs:string? ) as element()* {
  let $person := globals:collection('persons-uri')//Person[Id = $ref]
  return
    if ($person) then (
      <var name="{$prefix}_First_Name">{ $person/Name/FirstName/text() }</var>,
      <var name="{$prefix}_Last_Name">{ $person/Name/LastName/text() }</var>
      )
    else
      <var name="{$prefix}_First_Name">UNKNOWN ref({ $ref }) {$prefix}</var>
};

(: ======================================================================
   Returns the list of eXist groups that the $person user should belong to 
   NOTE: uses GlobalInformation 'en' section !
   ======================================================================
:)
declare function account:gen-groups-for-user( $person as element() ) as xs:string* {
  (
  "users",
  for $ref in $person/UserProfile/Roles/Role/FunctionRef/text()
  let $f := form:get-normative-selector-for('Functions')/Option[Id = $ref]
  return $f/@Group
  )
};

(: ======================================================================
   Function to generate a random password
   ======================================================================
:)
declare function account:gen-password ( $name as xs:string, $email as xs:string ) {
  let $boot := concat($name, current-dateTime(), $email)
  let $next := util:hash($boot,"md5")
  let $seed := 
        string-join(
    for $i in 1 to string-length($next)
    return
        if (($i mod 2 = 0) or ($i mod 3 = 0) or ($i mod 5 = 0)) then
          translate(substring($next, $i, 1),"012345", "aeiouy")
        else
          substring($next, $i, 1),
        ''
        )
  let $max := string-length($seed)
  return
    string-join(
      for $i in 1 to 8 
      return 
           let $pos := util:random($max)
           let $res := substring($seed, $pos, 1)
           return 
               if ($pos > $max div 2) then
                    upper-case($res)
               else
                    $res,
      '')
};

(: ======================================================================
   Sends an email message to inform a user of his/her new generated password
   on behalf of the user himself or of an application administrator
   ======================================================================
:)
declare function account:send-new-password( $user as element(), $pwd as xs:string, $to as xs:string, $askedByUser as xs:boolean ) as xs:boolean {
  let $template := if ($askedByUser) then 'new-password-by-user' else 'new-password-by-admin'
  let $from := if ($askedByUser) then () else media:gen-current-user-email(false())
  let $email :=
    media:render-email($template,
      <vars>
        <var name="Password">{ $pwd }</var>
        { local:gen-user-name('Admin', user:get-current-person-id()) }
        { local:gen-user-name('User', $user/Id/text()) }
      </vars>,
      'en'
      )
  return
    media:send-email('account', $from, $to, $email/Subject/text(), media:message-to-plain-text($email/Message))
};

(: ======================================================================
   Sends an email message to inform a user of his new account information to access the application
   on behalf of an application administrator
   ======================================================================
:)
declare function account:send-created-login( $user as element(), $login as xs:string, $pwd as xs:string, $to as xs:string) as xs:boolean {
  let $from := media:gen-current-user-email(false())
  let $email :=
    media:render-email('login-created',
      <vars>
        <var name="Login">{ $login }</var>
        <var name="Password">{ $pwd }</var>
        { local:gen-user-name('Admin', user:get-current-person-id()) }
        { local:gen-user-name('User', $user/Id/text()) }
      </vars>,
      'en'
      )
  return
    media:send-email('account', $from, $to, $email/Subject/text(), media:message-to-plain-text($email/Message))
};

(: ======================================================================
   Sends an email message to inform a user of his updated account information to access the application
   on behalf of an application administrator
   ======================================================================
:)
declare function account:send-updated-login( $user as element(), $login as xs:string, $pwd as xs:string, $to as xs:string ) as xs:boolean {
  let $from := media:gen-current-user-email(false())
  let $email :=
    media:render-email('login-updated',
      <vars>
        <var name="Login">{ $login }</var>
        <var name="Password">{ $pwd }</var>
        { local:gen-user-name('Admin', user:get-current-person-id()) }
        { local:gen-user-name('User', $user/Id/text()) }
      </vars>,
      'en'
      )
  return
    media:send-email('account', $from, $to, $email/Subject/text(), media:message-to-plain-text($email/Message))
};
