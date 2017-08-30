xquery version "1.0";
(: ------------------------------------------------------------------
   XQuery Content Management Library

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Alert utilities to generate notifications and to archive alerts

   Functions called either as a consequence of user's status change
   or from batch scripts (e.g. batch assignment of regions) 

   March 2015 - (c) Copyright 2015 Oppidoc SARL. All Rights Reserved. 
   ------------------------------------------------------------------ :)

module namespace alert = "http://oppidoc.com/ns/xcm/alert";

declare namespace xdb = "http://exist-db.org/xquery/xmldb";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../../lib/globals.xqm";
import module namespace display = "http://oppidoc.com/ns/xcm/display" at "../../lib/display.xqm";
import module namespace user = "http://oppidoc.com/ns/xcm/user" at "../../lib/user.xqm";
import module namespace media = "http://oppidoc.com/ns/xcm/media" at "../../lib/media.xqm";
import module namespace check = "http://oppidoc.com/ns/xcm/check" at "../../lib/check.xqm";
import module namespace workflow = "http://oppidoc.com/ns/xcm/workflow" at "workflow.xqm";
import module namespace email = "http://oppidoc.com/ns/xcm/mail" at "../../lib/mail.xqm";

(: ======================================================================
   Returns prefixed variables xxx_First_Name and xxx_Last_Name for a set of users
   ======================================================================
:)
declare function alert:gen-user-name-for( $prefix as xs:string, $refs as xs:string* ) as element()* {
  if (empty($refs)) then
    <var name="{$prefix}_Last_Name">(WARNING) {upper-case($prefix)} NOT ASSIGNED YET</var>
  else
    for $ref in $refs
    let $person := globals:collection('persons-uri')//Person[Id = $ref]
    return
      if ($person) then (
        <var name="{$prefix}_First_Name">{ $person/Information/Name/FirstName/text() }</var>,
        <var name="{$prefix}_Last_Name">{ $person/Information/Name/LastName/text() }</var>
        )
      else
        <var name="{$prefix}_First_Name">UNKNOWN ref({ $ref }) {$prefix}</var>
};

(: ======================================================================
   Utility to return variables representing current user name
   ======================================================================
:)
declare function alert:gen-current-user-name() as element()* {
  let $uid := user:get-current-person-id()
  let $user := globals:collection('persons-uri')//Person[Id = $uid]
  return (
    <var name="User_First_Name">{ $user/Name/FirstName/text() }</var>,
    <var name="User_Last_Name">{ $user/Name/LastName/text() }</var>
    )
};

(: ======================================================================
   Utility to return variables representing current user name
   ======================================================================
:)
declare function alert:gen-action-status-names( $from as xs:string?, $to as xs:string, $workflow as xs:string ) as element()* {
  let $status := display:gen-name-for-sref(concat($workflow, 'WorkflowStatus'), $to, 'en')
  let $verb := if ($from and (number($from) > number($to))) then "returned back" else "moved forward"
  return (
    <var name="Action_Verb">{ $verb }</var>,
    <var name="Status_Name">{ $status }</var>
    )
};

(: ======================================================================
   Returns '-nologin' if the user ref hasn't got a login
   ======================================================================
:)
declare function alert:check-user-has-login( $ref as element()? ) as xs:string {
  if ($ref) then 
    let $login := normalize-space(globals:collection('persons-uri')//Person[Id = $ref/text()]/UserProfile/Username) (: FIXME: become inconsistent since using ECAS we cannot assert it (?) :)
    return 
      if ($login and xdb:exists-user($login)) then '' else '-nologin'
  else
    ''
};

(: ======================================================================
   Sends an email to a list of recipients by reference using the category channel
   The from parameter will become the email reply-to field it must contains 
   a valid e-mail address if defined, defaults to DefaultEmailSender in settings.xml
   Mail subject / message are passed with an email model such as a rendered email template
   Recipients '-1' is a pass-through recipients used for archiving only
   If there is a list of cc recipients by reference, they will be added 
   in carbon copy for each recipient, usually this should be used with a unique 
   recipient otherwise they will receive duplicated messages
   Returns a list of success and/or error elements for each recipient
   ======================================================================
:)
declare function alert:send-email-to( $category as xs:string, $from as xs:string?, $to as xs:string*, $cc as xs:string*, $mail as element() ) as element()* {
  let $subject := $mail/Subject/text()
  let $content := media:message-to-plain-text($mail/Message)
  let $to-cc := (: converts cc refs to e-mail addresses :)
    for $ref in $cc
    return
      if (check:is-email($ref)) then
        $ref
      else 
        let $p := globals:collection('persons-uri')//Person[Id eq $ref]
        return
          if (check:is-email($p/Information/Contacts/Email)) then
            $p/Information/Contacts/Email/text()
          else
            ()
  return
    for $ref in $to[. != '-1']
    let $p := globals:collection('persons-uri')//Person[Id = $ref]
    let $email := if (check:is-email($ref)) then $ref else $p/Information/Contacts/Email/text()
    return
      if ($email) then
        if (check:is-email($email)) then
          if (media:send-email($category, $from, $email, $to-cc, $subject, $content)) then
            if ($to-cc) then
              <success>{ $email } (with copy to {string-join($to-cc, ', ')})</success>
            else 
              <success>{ $email }</success>
          else
            <error>impossible to send e-mail to { $email }</error>
        else
          <error>malformed e-mail address "{ $email }" for { $p/Information/Name/FirstName } { $p/Information/Name/LastName }</error>
      else
        <error>unkown person with reference { $ref }</error>
};

(: ======================================================================
   Turns message model (either submitted from client or generated server-side) 
   into a normalized Alert element for archiving
   This can be either an Alert (automatic or spontaneous) with Addressees / Message
   or an Email with From / To / Message fields and an optional server-side generated attachment
   Always sets SenderKey to current user
   ======================================================================
:)
declare function local:gen-message-for-writing(
  $cur-status as xs:string?,
  $prev-status as xs:string?,
  $model as element(),
  $attachment as element()?,
  $index as xs:double?
  ) as element()
{
  let $uid := user:get-current-person-id ()
  return
  <Alert>
    <Id>{ $index }</Id>
    <Date>{ current-dateTime() }</Date>
    <SenderKey>
      { 
      $model/@Mode,
      $uid 
      }
    </SenderKey>
    { 
      $model/(From | Addressees | To | Subject | Key),
      if ($cur-status) then <CurrentStatusRef>{ $cur-status }</CurrentStatusRef> else (),
      if ($prev-status) then <PreviousStatusRef>{ $prev-status }</PreviousStatusRef> else (),
      <Payload Generator="{ lower-case(local-name($model)) }">
        {
        $model/Message,
        $attachment
        }
      </Payload>
    }
  </Alert>
};

(: ======================================================================
   Archives a submitted message (Alert or Email) into the Case or Activity
   Returns the saved message (an Alert element) or an Oppidum error (an error element)
   ======================================================================
:)
declare function alert:archive(
  $parent as element(),
  $submitted as element(),
  $attachment as element()?,
  $cur-status as xs:string?,
  $prev-status as xs:string?,
  $lang as xs:string
  ) as element()?
{
  if (empty($parent/Alerts)) then
    let $save := local:gen-message-for-writing($cur-status, $prev-status, $submitted, $attachment, 1)
    return
      (
      update insert <Alerts LastIndex="1">{ $save }</Alerts> into $parent,
      $save
      )[last()]
  else
    if ($parent/Alerts/@LastIndex castable as xs:integer) then
      let $index := number($parent/Alerts/@LastIndex) + 1
      let $save := local:gen-message-for-writing($cur-status, $prev-status, $submitted, $attachment, $index)
      return
        (
        update value $parent/Alerts/@LastIndex with $index,
        update insert $save into $parent/Alerts,
        $save
        )[last()]
    else
      oppidum:throw-error("DB-INDEX-NOT-FOUND", ())
};

(: ======================================================================
   Converts @Key="key1 key2 ..." into Key elements for archiving with email 
   ====================================================================== 
:)
declare function alert:gen-keys( $key as attribute()? ) as element()* {
  for $k in tokenize($key, ' ')
  return <Key>{ $k }</Key>
};

(: ======================================================================
   Implements Recipients tag to send and archive an e-mail
   Returns a <Report Total="nb"> element containing the archived message 
   or empty in case it was not archived and the total number 
   of successful direct recipients (not including CC)
   FIXME: maybe we can Mix a To from template with To from Recipients (?)
   ====================================================================== 
:)
declare function alert:apply-recipients(
  $recipients as element()?,
  $category as xs:string,
  $case as element(),
  $activity as element()?,
  $alert as element(), 
  $from as xs:string?,
  $flow-to as xs:string?,
  $flow-from as xs:string?
  ) as element()
{
  let $send-to := workflow:gen-recipient-refs($recipients, (), $case, $activity)
  let $send-cc := (workflow:gen-recipient-refs($recipients/@CC, (), $case, $activity), $alert/CC/text())
  return
    let $to :=
      if ($alert/To) then (: To (from e-mail template) has priority over Recipients :)
        $alert/To/text()
      else 
        $send-to
    let $total := count($to[. ne '-1']) (: -1 means nobody, archiving purpose :)
    let $res := alert:send-email-to($category, $from, $to, $send-cc, $alert)
    let $done := if ($total eq 0) then 1 else count($res[local-name(.) eq 'success'])
    return
      <Report Total="{ $done }" Message="{ string-join($res, ', ') }">
        {
        if ($done > 0) then (: succeeded for at list one recipient => archives it :)
          let $home := if ($activity) then $activity else $case
          (: TODO: test @Archive eq 'no' :)
          let $archive := (: merges to and cc for archival :)
            <Alert>
              { $alert/@Mode }
              <Addressees>
                {
                for $a in $send-to
                return <AddresseeKey>{ $a }</AddresseeKey>,
                for $a in $send-cc
                return 
                  if (check:is-email($a)) then
                    <Addressee CC="1">{ $a }</Addressee>
                  else
                    <AddresseeKey CC="1">{ $a }</AddresseeKey>
                }
              </Addressees>
              { 
              $alert/(To | From | Subject | Message),
              alert:gen-keys($recipients/@Key)
            }
            </Alert>
          return
            alert:archive($home, $archive, (), $flow-to, $flow-from, 'en')
        else
          (: failed for all, should we archive it with a flag ? :) 
          ()  
        }
      </Report>
};

(: ======================================================================
   Implements an automatic alerts associated a transition
   That means it generates, sends and archives the alert
   $recipients is a Recipient element (with an optional CC attribute)
   If $recipient is empty the e-mail template must provide a To field
   with a real e-mail address
   Returns Oppidum success or error message (e.g. in Flash for asynch reporting)
   Note that this is a combination of local:prefill-message 
   and local:add-notification in alert.xql
   ====================================================================== 
:)
declare function alert:notify-transition(
  $transition as element(), 
  $workflow as xs:string, 
  $case as element(), 
  $activity as element()?,
  $name as xs:string?, 
  $recipients as element()?
  ) as element()* 
{
  let $host := if ($activity) then $activity else $case
  return 
    if (($recipients/@Max eq '1') and ($recipients/@Key) and ($host/Alerts/Alert[Key eq tokenize($recipients/@Key, ' ')[1]])) then
      (: automatic notification with no duplicate e-mail :)
      let $date := display:gen-display-date(($host/Alerts/Alert[Key eq tokenize($recipients/@Key, ' ')[1]])[1]/Date, 'en')
      return
        oppidum:add-message($recipients/@Explain, $date, true())
    else
      let $wf-from := string($transition/@From)
      let $wf-to := string($transition/@To)
      let $template :=  (: name of e-mail template to used :)
        if ($name) then
          if ($name eq 'kam-notification') then (: DEPRECATED (UNUSED): conditional "-nologin" suffix trick :)
            concat($name, alert:check-user-has-login($case/Management/AccountManagerKey))
          else
            $name
        else (: default one :)
          concat(lower-case($workflow), '-workflow-transition')
      let $extra-vars := alert:gen-action-status-names($wf-from, $wf-to, $workflow) (: not in variables.xml :)
      let $alert := email:render-alert($template, 'en', $case, $activity, $extra-vars)
      return
        let $from :=
          if ($alert/From) then (: sender defaults to current user :)
            $alert/From/text() 
          else 
            media:gen-current-user-email(false())
        let $report := alert:apply-recipients($recipients, 'workflow', $case, $activity, $alert, $from, $wf-to, $wf-from)
        return (
          if ($report/@Total ne '0') then
            $report/*
          else 
            (: not sent because of error and not archived :)
            (),
          oppidum:add-message('NOTIFY-TRANSITION-REPORT', $report/@Message, true())
          )
};  


