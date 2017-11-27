xquery version "1.0";
(: ------------------------------------------------------------------
   XQuery Content Management Library

   Creator: Stéphane Sire <s.sire@opppidoc.fr>

   Shared functions to display workflow user interface and to implement 
   workflow actions as specified in application.xml

   Contains the functions to generate an HTML fragment to display the entities
   which can be added inside a drawer, these are used when generating

   FIXME:
   - actually the breadcrumb functionality supposes the case subject 
     and the activity subject are identified with a No element 

   January 2014 - (c) Copyright 2014 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

module namespace workflow = "http://oppidoc.com/ns/xcm/workflow";

import module namespace request="http://exist-db.org/xquery/request";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../../lib/globals.xqm";
import module namespace display = "http://oppidoc.com/ns/xcm/display" at "../../lib/display.xqm";
import module namespace access = "http://oppidoc.com/ns/xcm/access" at "../../lib/access.xqm";
import module namespace ajax = "http://oppidoc.com/ns/xcm/ajax" at "../../lib/ajax.xqm";
import module namespace media = "http://oppidoc.com/ns/xcm/media" at "../../lib/media.xqm";
import module namespace alert = "http://oppidoc.com/ns/xcm/alert" at "alert.xqm";

(: ======================================================================
   Returns a list of person identifiers with the given role or an empty sequence.
   Implements semantic roles against the optional subject and object
   as defined by the Groups element of application.xml
   The person identifiers are expected to be application Person identifiers
   or eventually e-mail addresses when calling this to send e-mail notifications
   See also access:assert-semantic-role in lib/access.xqm for access control
   ======================================================================
:)
declare function workflow:get-persons-for-role ( $role as xs:string, $subject as element()?, $object as element()? ) as xs:string* {
  let $prefix := substring-before($role, ':')
  let $suffix := substring-after($role, ':')
  return
    if ($prefix eq 'u') then (: targets specific user :)
      globals:collection('persons-uri')//Person[UserProfile/Username = $suffix]/Id/text() (: FIXME: realm ? :)
    else if ($prefix eq 'g') then (: targets users belonging to a generic group :)
      let $group-ref := globals:get-normative-selector-for('Functions')/Option[@Role eq $suffix]/Value
      return
        globals:collection('persons-uri')//Person[UserProfile/Roles/Role/FunctionRef eq $group-ref]/Id/text()
    else  if ($prefix eq 'r') then
      let $group := globals:doc('application-uri')/Application/Security/Groups/Group[@Name eq $suffix]/Meet
      return
        if ($group) then
          util:eval($group)
        else
          false()
    else
      ()
};

(: ======================================================================
   Converts a list of Addressees into a tag named element containing a 
   comma separated list with all unreferenced person's name for AddresseeKey
   elements and direct email or name for Addressee elements
   ====================================================================== 
:)
declare function local:gen-addressees-for-viewing( $tag as xs:string, $addr as element()*, $lang as xs:string ) as element()? {
  if ($addr) then
    element { $tag } 
      {
      string-join(
        for $a in $addr
        return
          if (local-name($a) eq 'Addressee') then
            $a
          else if ($a eq '-1') then
            'nobody'
          else
            display:gen-person-name($a, $lang),
        ', '
        ) (: space after comma is important to garantee visualization in the browser :)
      }
  else
    ()
};

(: ======================================================================
   Transforms an alert message model into one of two screen display oriented models

   If $base is set it represents the base path to add before "alerts/#no" 
   to generate the link to open up the alert in a modal window.
   
   Note $base is optional because :
   - if set the model is generated to display a table row summary
   - if not set the model is generated to display the modal alert details window

   Note per construction To is exclusive of Addressees output (but not of CC) because e-mail
   templates with a To element (see email.xml) overwrite any other principal recipients,
   it can only be combined with CC recipients (see also alert:notify-transition in alert.xqm)

   FIXME: remove dependency on hard-coded group names, handle direct Email in Addressees
   ======================================================================
:)
declare function workflow:gen-alert-for-viewing ( $workflow as xs:string, $lang as xs:string, $item as element(), $base as xs:string? ) as element()
{
  <Alert>
    {
    if ($base) then
      attribute { 'Base' } { $base }
    else
      let $usergroups := oppidum:get-current-user-groups()
      return
        if ($item/Payload[@Generator eq 'email']) then (: e.g. SME Agreement Email, SME feedback form Email :)
          <Email>
          {
          if ($usergroups = ('coaching-assistant','coaching-manager','admin-system')) then
            $item/Payload/Message
          else
            media:obfuscate($item/Email/Message),
          if ($item/Payload/Attachment) then
            <Attachment>{ media:message-to-plain-text($item/Payload/Attachment) }</Attachment>
          else
            ()
          }
          </Email>
        (: Workflow status changes alert :)
        else if ($usergroups = ('coaching-assistant','coaching-manager','admin-system')) then
          $item/Payload
        else
          media:obfuscate($item/Payload),
    $item/Id, 
    <Date>
      {
      (: Displays timestamp as date plus time :)
      let $value := string($item/Date)
      return
        if (string-length($value) > 10) then
          concat(display:gen-display-date(substring($value, 1, 10), $lang), ' ', substring($value, 12, 5))
        else
          display:gen-display-date($value, $lang)
      }
    </Date>,
    <ActivityStatus>
      { 
      (: TODO: annotate CurrentStatusRef with extra @Workflow if heuristic can't work :)
      let $workflow := local-name($item/CurrentStatusRef/ancestor::Alerts/parent::*)
      return display:gen-name-for(concat($workflow, 'WorkflowStatus'), $item/CurrentStatusRef, $lang)
      }
    </ActivityStatus>,
    $item/Subject,
    if ($item/SenderKey) then
      <Sender>
        {
        $item/SenderKey/@Mode,
        display:gen-person-name($item/SenderKey,$lang)
        }
      </Sender>
    else
      (),
    $item/From,
    $item/To,
    local:gen-addressees-for-viewing('Addressees', $item/Addressees/*[empty(@CC)], $lang),
    local:gen-addressees-for-viewing('CC', $item/Addressees/*[@CC], $lang)
    }
  </Alert>
};

(: ======================================================================
   Turns a row opinion into an opinion model to be transformed to HTML by workflow.xsl
   ======================================================================
:)
declare function workflow:gen-otheropinion-for-viewing ( $lang as xs:string, $item as element() ) as element()
{
  <OtherOpinion>
    <Date>{display:gen-display-date($item/Date,$lang)}</Date>
    {$item/Author}
    {$item/Comment}
  </OtherOpinion>
};

(: ======================================================================
   Turns a row logbook item into a logbook model to be transformed to HTML by workflow.xsl
   The $canDelete flag indicates wether user can delete the entry, we set it on each item
   for the case where it is generated inside an Ajax creation request
   DEPRECATED
   ======================================================================
:)
declare function workflow:gen-logbook-item-for-viewing ( $lang as xs:string, $item as element(), $canDelete as xs:boolean ) as element()
{
  <LogbookItem data-id="{$item/Id}">
    { if ($canDelete) then attribute { 'Delete' } { 'yes' } else () }
    <Date>{display:gen-display-date($item/Date,$lang)}</Date>
    <CoachRef>
      {display:gen-person-name($item/CoachRef,$lang)}
    </CoachRef>
    {$item/NbOfHours}
    {$item/ExpenseAmount}
    {$item/Comment}
  </LogbookItem>
};

(: ======================================================================
   Turns an appendix meta-data record into an annex model to be transformed to HTML by workflow.xsl
   To be called to build annexes tab content in workflow view, or to render a single row after Ajax upload
   For legacy reason the $item with meta-data is optional
   ======================================================================
:)
declare function workflow:gen-annexe-for-viewing (
  $lang as xs:string,
  $item as element()?,
  $filename as xs:string,
  $activity-no as xs:string,
  $base as xs:string?,
  $canDelete as xs:boolean ) as element()
{
  let $url := concat($activity-no, '/docs/', $filename)
  return
    <Annex>
      {
      if ($item) then
        (
        <Date SortKey="{$item/Date/text()}">
          { display:gen-display-date($item/Date, $lang) }
        </Date>,
        <ActivityStatus>
          { "display:gen-activity-status-name" (: TODO: display:gen-activity-status-name($item/ActivityStatusRef,$lang):) }
        </ActivityStatus>,
        <Sender>
          { display:gen-person-name($item/SenderRef,$lang) }
        </Sender>
        )
      else if ($base) then (: legacy appendix w/o meta-data :)
        let $date := string(xdb:created($base, $filename))
        return
          <Date SortKey="{$date}">
            { display:gen-display-date($date, $lang) }
          </Date>
      else
        ()
      }
      <File href="{$url}">
        { if ($canDelete) then attribute { 'Del' } { 1 } else () }
        { $filename }
      </File>
    </Annex>
};

(: ======================================================================
   Facade to call complete function with implicit target modal identifier
   ====================================================================== 
:)
declare function workflow:gen-status-change(
  $current-status as xs:string,
  $workflow as xs:string,
  $subject as element(),
  $object as element()?,
  $id as xs:string?
  ) as element()*
{
  workflow:gen-status-change($current-status, $workflow, $subject, $object, $id, 'c-alert')
};

(: ======================================================================
   Generates ChangeStatus model with Status commands to render a menu 
   with commands to change workflow status. Each Status commands can open
   the optional modal window configured by @TargetEditor 
   (usually to edit/send an e-mail) upon success unless Ajax response 
   contains <done/>. In the later case directly redirects to the Location
   header from the Ajax response. Note the $target-modal target editor 
   is mandatory even if you don't send an e-mail (AXEL command API limitation)
   TODO: ajouter AutoExec="name"
   ====================================================================== 
:)
declare function workflow:gen-status-change(
  $current-status as xs:string,
  $workflow as xs:string,
  $subject as element(),
  $object as element()?,
  $id as xs:string?,
  $target-modal as xs:string
  ) as element()*
{
  if (($workflow eq 'Case') and (count($subject//Activity) > 0)) then (: specific to genuine case tracker :)
    ()
  else
    let $moves :=
      for $transition in globals:doc('application-uri')//Workflow[@Id eq $workflow]//Transition[@From = $current-status][@To ne '-1'][not(@TriggerBy)]
      (:where access:check-status-change($transition, $subject, $object):)
      return $transition
    return
      if ($moves) then
        <ChangeStatus Status="{ $current-status }" TargetEditor="{ $target-modal }">
          {
          if ($id) then attribute { 'Id' } { $id } else (),
          for $transition in $moves
          let $from := number($transition/@From)
          let $to := if ($transition/@To castable as xs:integer) then number($transition/@To) else ()
          let $action := if ($to) then if ($from <= $to) then 'increment' else 'decrement' else if ($transition/@To eq 'last()') then 'revert' else () 
          let $arg := if ($to) then if ($from >= $to) then $from - $to else $to - $from else ()
          return
            if ($action) then
              <Status Action="{$action}">
                {
                $transition/@data-confirm-loc,
                if ($to) then attribute { 'Argument' } { $arg } else (),
                if ($to) then attribute { 'To' } { $to } else (),
                $transition/(@Intent | @Label | @Id)
              }
              </Status>
            else (: TODO: throw syntax error ? :)
              ()
          }
        </ChangeStatus>
      else
        <ChangeStatus/> (: in case there is an isolated Spawn, FIXME: move Spawn inside :)
};

(: ======================================================================
   Adds extra parameters to the template URL according to application.xml
   Implements <Flag> element
   Implement @Param of <Template> element
   ======================================================================
:)
declare function local:configure-template( $doc as element(), $case as element(), $activity as element()? ) as xs:string {
  let $workflow := if ($activity) then 'Activity' else 'Case'
  let $flags :=
    for $f in $doc/Host/Flag
    let $root := string($f/parent::Host/@RootRef)
    return
      if (access:check-workflow-permissions(string($f/@Action), $workflow, $root, $case, $activity)) then
      (:if (access:check-document-permissions(string($f/@Action), $root, $case, $activity)) then:)
        concat(string($f/@Name), '=1')
      else
        ()
  let $params := (
    if (contains($doc/Template/@Param, 'breadcrumbs')) then
      concat('case=', $case/No, if ($activity) then concat('&amp;activity=', $activity/No) else ())
    else
      ()
    )
  let $parameters := ($flags, $params)
  return
    if (count($parameters) >= 1) then
      concat('&amp;', string-join($parameters, '&amp;'))
    else
      ''
};

(: ======================================================================
   Returns a context={Document/@Context} parameter or the empty string
   The context parameter is used to share a resource controller between
   different document editors
   ======================================================================
:)
declare function local:configure-resource( $doc as element() ) as xs:string {
  if ($doc/@Context) then
    concat('&amp;context=', $doc/@Context)
  else
    ''
};

(: ======================================================================
   Asserts activity data is compatible with document to display
   ======================================================================
:)
declare function workflow:assert-rules( $assert as element(), $case as element(), $activity as element()?, $base as element()? ) as xs:boolean {
let $rules := $assert/true
    return
      if (count($rules) > 0) then
        every $expr in $rules satisfies util:eval($expr/text())
      else
        false()
};

(: ======================================================================
   Checks if there are some assertions that prevent document to display in
   accordion.
   Returns the empty sequence in case there are no assertions to check 
   or they are all successful, returns a non-void sequence otherwise
   ======================================================================
:)
declare function workflow:validate-document($documents as element(), $doc as element(), $cur-status as xs:string+, $case as element(), $activity as element()? ) as xs:boolean {
  count(
    for $assert in $doc/DynamicAssert
    return
      if ($cur-status = tokenize($assert/@AtStatus, " ")) then
        (: check for availability of some documents :)
        if (count($assert/Tab) > 0 ) then
          if (string($assert/@Rule) eq 'some') then
            if (some $tab in $assert/Tab satisfies workflow:validate-document($documents, $documents/Document[string(@Tab) eq $tab], $cur-status, $case, $activity)) then
              ()
            else (: zero implied documents are displayed so this one too :)
              '0'
          else if (string($assert/@Rule) eq 'all') then
            if (every $tab in $assert/Tab satisfies workflow:validate-document($documents, $documents/Document[string(@Tab) eq $tab], $cur-status, $case, $activity)) then
              ()
            else (: not all implied documents are displayed so this one too :)
              '0'
          else (: no rule yields an error :)
            '0'
        (: check for availability of some data :)
        else if (count($assert/true) > 0) then
          let $base := util:eval($assert/@Base)
          return
            if (string($assert/@Rule) eq 'some') then
              if (some $expr in $assert/true satisfies util:eval($expr/text())) then () else '0'
            else if (string($assert/@Rule) eq 'all') then 
              if (every $expr in $assert/true satisfies util:eval($expr/text())) then () else '0'
            else (: no rule yields an error :)
              '0'
        else (: not aware of the current status, no fail :)
          ()
      else
        ()
  ) = 0
};

(: ======================================================================
   Generates view model to display Case or Activity workflow
   ======================================================================
:)
declare function workflow:gen-information( $workflow as xs:string, $case as element(), $activity as element()?, $lang as xs:string ) {
  let $target := if ($workflow eq 'Case') then $case else $activity
  let $prev-status := $target/StatusHistory/PreviousStatusRef/text()
  let $cur-status := $target/StatusHistory/CurrentStatusRef/text()
  let $concur-status := $target/StatusHistory/ConcurrentStatusRef/text()
  let $all-status := ($cur-status, $concur-status)
  let $status-def := globals:get-normative-selector-for(concat($workflow, 'WorkflowStatus'))/Option[Value eq $cur-status]
  let $cur := if ($status-def/@Type eq 'final') then $prev-status else $cur-status
  return
    <Accordion CurrentStatus="{$cur-status}">
      {
      let $documents := globals:doc('application-uri')//Workflow[@Id eq $workflow]/Documents
      for $doc in $documents/Document[not(@Accordion) or (@Accordion eq 'no')][not(@Deprecated)]
      (: FIXME: we have to find a trick to allow some role to update at any status :)
      let $actions := 
        for $a in $doc/Action[tokenize(string(@AtStatus), " ") = $all-status]
        where (string($a/@Type) ne 'status')
              or (: keeps only latest 'status' action :)
              not(
                 some $x in $doc/following-sibling::Document[tokenize(string(@AtStatus), " ") = $cur]/Action[@Type eq 'status'] 
                 satisfies tokenize(string($x/@AtStatus), " ") = $all-status
                 )
        return $a
      let $suffix := if ($doc/@Blender eq 'yes') then 'blend' else 'xml'
      return
        (: selects visible documents : either testing current status or previous status if current status is a "cementary" state :)
        (: FIXME: why $cur ? :)
        if (((tokenize(string($doc/@AtStatus), " ") = $all-status) or ($all-status = tokenize(string($doc/@AtFinalStatus), " "))) and (workflow:validate-document($documents, $doc, $all-status, $case, $activity))) then
          <Document Status="current">
          {(
          $doc/@class,
          (: quick implementation to pre-open an accordion document :)
          if ($doc/@PreOpenAtStatus and tokenize($doc/@PreOpenAtStatus, " ") = $cur-status) then
            attribute  { 'data-accordion-status' } { 'opened' }
          else 
            (),
          attribute { 'Id' } { string($doc/@Tab) },
          <Name loc="workflow.title.{$doc/@Tab}">{string($doc/@Tab)}</Name>,
          if ($doc/Controller) then
            <Resource>{$doc/Controller/text()}.{$suffix}?goal=read{local:configure-resource($doc)}</Resource>
          else
            (),
          if ($doc/Template) then
            <Template>
             {
             string($doc/parent::Documents/@TemplateBaseURL)}{$doc/Template/text()}?goal=read{local:configure-template($doc, $case, $activity)
             }
            </Template>
          else
            (),
          $doc/Content,
          if ($actions) then
            <Actions>
              {
              for $a in $actions
              return
                if ($a/@Type = ('update', 'delete', 'drawer')) then
                  let $verb := string($a/@Type)
                  let $control := globals:doc('application-uri')/Application/Security/Documents/Document[@TabRef = string($doc/@Tab)]
                  let $rules := $control/Action[@Type eq $verb]
                  return
                    if (access:assert-access-rules($rules, $case, $activity)) then
                      if ($verb eq 'update') then
                        <Edit>
                          { $a/@Forward }
                          <Resource>{$doc/Controller/text()}.xml?goal=update</Resource>
                          <Template>{string($doc/parent::Documents/@TemplateBaseURL)}{$doc/Template/text()}?goal=update{local:configure-template($doc, $case, $activity)}</Template>
                        </Edit>
                      else if ($verb eq 'drawer') then
                          <Drawer>
                            { 
                            $a/@Forward,
                            $a/@loc,
                            $a/@AppenderId,
                            let $controller := if ($doc/Controller) then $doc/Controller else $a/Controller
                            let $template := if ($doc/Template) then $doc/Template else $a/Template
                            return (
                              <Controller>{$controller/text()}</Controller>,
<Template>{ string($doc/parent::Documents/@TemplateBaseURL)}{ $template/text() }?goal=create{local:configure-template($doc, $case, $activity) }</Template>
                              )
                            }
                          </Drawer>
                      else if ($verb eq 'delete' and (empty($a/@Render) or $a/@Render ne 'off')) then
                        <Delete/>
                      else
                        ()
                    else if (request:get-parameter('roles', ())) then  (: FIXME: temporary :)
                      <Debug>{ $rules }</Debug>
                    else
                      ()
                else if ($a/@Type eq 'status') then
                  let $from-status := if ($a/@Group) then 
                                        $target/StatusHistory/ConcurrentStatusRef[@Group eq $a/@Group]
                                      else
                                        $cur-status
                  return
                    if ($from-status) then
                      workflow:gen-status-change($from-status, $workflow, $case, $activity, $a/Id)
                    else
                      ()
                else if ($a/@Type eq 'spawn') then
                  let $control := globals:doc('application-uri')/Application/Security/Documents/Document[@TabRef eq string($a/@ProxyTab)]
                  let $rules := $control/Action[@Type eq 'create']
                  return
                    if (access:assert-access-rules($rules, $case, $activity)) then
                      let $proxy := globals:doc('application-uri')//Workflow[@Id eq $workflow]/Documents/Document[@Tab eq string($a/@ProxyTab)]
                      return
                        <Spawn>
                          { $a/@Id }
                          <Controller>{$proxy/Controller/text()}</Controller>
                        </Spawn>
                    else
                      ()
                else if ($a/@Type eq 'read') then (: read access limited to subset of allowed users :) 
                  let $control := globals:doc('application-uri')/Application/Security/Documents/Document[@TabRef = string($doc/@Tab)]
                  let $rules := $control/Action[@Type eq 'read']
                  return
                    if (access:assert-access-rules($rules, $case, $activity)) then
                      ()
                    else 
                      <Forbidden/>
                else
                  ()
              }
            </Actions>
          else
            (),
          if ($doc/AutoExec/@AtStatus eq $cur) then $doc/AutoExec else ()
          )}
          </Document>
        else
          ()
      }
    </Accordion>
};

declare function workflow:get-transition-for( $workflow as xs:string, $from as xs:string, $to as xs:string ) {
  globals:doc('application-uri')//Workflow[@Id eq $workflow]//Transition[@From eq $from][@To eq $to]
};

(: ======================================================================
   Checks if there are some assertions that prevent transition 
   Returns the empty sequence in case there are no assertions to check 
   or they are all successful, returns an error message type string otherwise
   Uses an overwritable subject because the assertion mechanism is always 
   run against a unique subject variable which is substituted by the object 
   when this later is available
   FIXME: maybe we should consider asserting against a subject AND an object ?
   ======================================================================
:)
declare function workflow:validate-transition( $transition as element(), $overwritable-subject as element(), $object as element()? ) as xs:string* {
  for $assert in $transition/Assert
  return
    if ($assert/@Error) then
      let $subject := if (exists($object)) then $object else $overwritable-subject
      return
        if (access:assert-transition-partly($subject, $assert, util:eval($assert/@Base))) then
          ()
        else
          string($assert/@Error)
    else
      ()
};

(: ======================================================================
   Stub to call the second version below
   ======================================================================
:)
declare function workflow:apply-transition( $transition as element(), $case as element(), $activity as element()? ) as element()? {
  if ($transition/@To eq 'last()') then
    let $history := if ($activity) then $activity/StatusHistory else $case/StatusHistory
    let $previous := if ($transition/@Group) then 
                       $history/ConcurrentPreviousStatusRef[@Group eq $transition/@Group]/text()
                     else
                       $history/PreviousStatusRef/text()
    return
      if (exists($previous)) then
        if ($transition/@Group) then
          workflow:apply-concurrent-transition-to($transition/@Group, $previous, $case, $activity)
        else
          workflow:apply-transition-to($previous, $case, $activity)
      else
        ()
  else if ($transition/@Group) then
    workflow:apply-concurrent-transition-to($transition/@Group, $transition/@To, $case, $activity)
  else
    workflow:apply-transition-to(string($transition/@To), $case, $activity)
};

(: ======================================================================
   Sets new workflow status for the activity if defined or for the case otherwise
   Returns empty sequence or an oppidum error if no status history model
   NOTE that it does not check the transition is allowed, this must be done before
   ======================================================================
:)
declare function workflow:apply-transition-to( $new-status as xs:string, $case as element(), $activity as element()? ) as element()? {
  let $history := if ($activity) then $activity/StatusHistory else $case/StatusHistory
  let $previous := $history/PreviousStatusRef
  let $current := $history/CurrentStatusRef
  let $status-log := $history/Status[ValueRef = $new-status]
  return
    if ($history) then (: sanity check :)
      (
      if ($previous) then
        update value $previous with $current/text()
      else (: first lazy creation :)
        update insert <PreviousStatusRef>{$current/text()}</PreviousStatusRef> following $current,
      if ($current) then
        update value $current with $new-status
      else (: should not happen :)
        (),
      if (empty($status-log)) then
        let $log :=
          <Status>
            <Date>{current-dateTime()}</Date>
            <ValueRef>{$new-status}</ValueRef>
          </Status>
        return
          update insert $log into $history
      else
        update replace $status-log/Date with <Date>{current-dateTime()}</Date> 
      )
    else
      oppidum:throw-error("WFSTATUS-NO-HISTORY", ())
};

(: ======================================================================
   Same as above but for a concurrent transition group
   ====================================================================== 
:)
declare function workflow:apply-concurrent-transition-to( $group as xs:string, $new-status as xs:string, $case as element(), $activity as element()? ) as element()? {
  let $history := if ($activity) then $activity/StatusHistory else $case/StatusHistory
  let $previous := $history/ConcurrentPreviousStatusRef[@Group eq $group]
  let $current := $history/ConcurrentStatusRef[@Group eq $group]
  let $status-log := $history/Status[ValueRef = $new-status]
  return
    if ($history) then (: sanity check :)
      (
      if ($previous) then
        update value $previous with $current/text()
      else (: first lazy creation :)
        update insert <ConcurrentPreviousStatusRef Group="{ $group }">{$current/text()}</ConcurrentPreviousStatusRef> following $current,
      if ($current) then
        update value $current with $new-status
      else (: should not happen :)
        (),
      if (empty($status-log)) then
        let $log :=
          <Status>
            <Date>{current-dateTime()}</Date>
            <ValueRef>{$new-status}</ValueRef>
          </Status>
        return
          update insert $log into $history
      else
        update replace $status-log/Date with <Date>{current-dateTime()}</Date> 
      )
    else
      oppidum:throw-error("WFSTATUS-NO-HISTORY", ())
};

(: ======================================================================
   Helper to generate the To attribute value for the requested transition
   Pre-condition: from and argument (if present) coded as numbers
   ====================================================================== 
:)
declare function local:decode-status-to( $action as xs:string, $from as xs:string, $argument as xs:string? ) as xs:string? {
  if ($action eq 'increment') then 
    string(number($from) + number($argument))
  else if ($action eq 'decrement') then
    string(number($from) - number($argument))
  else if ($action eq 'revert') then
    'last()'
  else
    ()
};

(: ======================================================================
   Implements Ajax 'status' command protocol
   Checks and returns a Transition element for a given workflow type
   or throws and returns an error element
   ======================================================================
:)
declare function workflow:pre-check-transition( $m as xs:string, $type as xs:string, $subject as element()?, $object as element()? ) as element() {
  let $item := if ($type eq 'Case') then $subject else $object
  let $action := request:get-parameter('action', ())
  let $argument := request:get-parameter('argument', 'nil')
  let $from := request:get-parameter('from', "-1")
  return
    if (exists($subject)) then
      if (($m = 'POST') and $item) then
        let $cur-status := $item/StatusHistory/CurrentStatusRef
        let $concur-status := $item/StatusHistory/ConcurrentStatusRef
        return
          if (not($from = ($cur-status, $concur-status))) then
            ajax:throw-error('WFSTATUS-ORIGIN-ERROR', ())
          else if (not($cur-status castable as xs:decimal)) then
            ajax:throw-error('WFSTATUS-SYNTAX-ERROR', ())
          else if (not($action = ('revert', 'increment', 'decrement'))) then
            ajax:throw-error('WFSTATUS-SYNTAX-ERROR', ())
          else if (($action = ()) and not($argument castable as xs:decimal)) then
            ajax:throw-error('WFSTATUS-SYNTAX-ERROR', ())
          else
            let $to := local:decode-status-to($action, $from, $argument)
            let $transition := workflow:get-transition-for($type, $from, $to)
            return
              if (not($transition)) then
                ajax:throw-error('WFSTATUS-NO-TRANSITION', ())
              else if (not(access:check-status-change($transition, $subject, $object))) then
                ajax:throw-error('WFSTATUS-NOT-ALLOWED', ())
              else
                (: checks if some document is missing data :)
                let $omissions := workflow:validate-transition($transition, $subject, $object)
                return
                  if (count($omissions) gt 1) then
                    let $explain :=
                      string-join(
                        for $o in $omissions
                        let $e := ajax:throw-error($o, ())
                        return $e/message/text(), '&#xa;&#xa;')
                    return
                      ajax:throw-error(string($transition/@GenericError), concat('&#xa;&#xa;',$explain))
                  else if ($omissions) then
                    ajax:throw-error($omissions, ())
                  else
                    (: everything okay, returns Transition element :)
                    $transition
      else
        ajax:throw-error('URI-NOT-SUPPORTED', ())
    else
      ajax:throw-error('WFSTATUS-MISSING-SUBJECT', ())
};

(: ======================================================================
   Returns a list of recipients for the given transition from to to of the case (or activity).
   Returns a sequence of AddresseeKey elements inside an Addressees element.
   The target specifies if it is a 'Case' or 'Activity' transition.
   DEPRECATED: to be replaced with workflow:gen-recipient-refs
   NOTE: not compatible with e-mail persons identifiers !
   ======================================================================
:)
declare function workflow:gen-recipients( $from as xs:string, $to as xs:string, $target as xs:string, $case as element(), $activity as element()? ) as element()*
{
  let $recipients := globals:doc('application-uri')//Workflow[@Id eq $target]/Transitions/Transition[@From eq $from][@To eq $to]/Recipients
  let $persons :=
    for $role in tokenize($recipients/text(), ' ')
    return workflow:get-persons-for-role($role, $case, $activity)
  return
    if (count($persons) > 0) then
      <Addressees T="{$target}" From="{$from}" To="{$to}" D="{$recipients}">
        {
        for $p in distinct-values($persons)
        return <AddresseeKey>{$p}</AddresseeKey>
        }
      </Addressees>
    else
      <Addressees T="{$target}" From="{$from}" To="{$to}" D="{$recipients}"/>
};

(: ======================================================================
   Returns a list of person identifiers (application Person identifier 
   oe e-mail identifier) or the empty sequence
   TODO: remove useless workflow parameter
   ====================================================================== 
:)
declare function workflow:gen-recipient-refs( $rule as xs:string?, $workflow as xs:string?, $case as element(), $activity as element()? ) as xs:string*
{
  let $persons :=
    for $role in tokenize($rule, ' ')
    return workflow:get-persons-for-role($role, $case, $activity)
  return 
    distinct-values($persons)
};

(: ======================================================================
   Implements automatic e-mail notifications found on the transition
   For each automatic e-mail specification found generates, sends and saves it

   Actually there are two parallels automatic e-mail definition mechanisms :
   - @Mail="direct" set on the Transition element causes notification 
     to be sent directly instead of being reviewed by end-user client-side first
   - Email elements inside the Transition element are always sent directly

   This should be called after a successful transition with the success response
   so that it can inject <done/> into the response to short-circuit the e-mail
   dialog in the 'status' command client-side in case of direct mail (1st case)
   Always returns the initial success message or the augmented version

   Note that it should be called from a full pipeline so that notification success 
   or error messages are copied to the flash and communicated to the user.

   See config/application.xml
   ======================================================================
:)
declare function workflow:apply-notification(
  $workflow as xs:string,
  $success as element(),
  $transition as element(),
  $case as element(),
  $activity as element()?) as element()
{
  (
  (: 1. Implements Mail element protocol :)
  (: TODO: implement <Condition avoid="$case/Alerts/Alert[@Reason eq 'sme-fallback-notification']"/> :)
  for $mail in $transition/Email
  return alert:notify-transition($transition, $workflow, $case, $activity, $mail/@Template, $mail/Recipients),
  (: 2. Implements @Mail="direct" protocol :)
  if ($transition/@Mail eq 'direct') then (
    (: short-circuit e-mail window, see also 'status' js command :)
    alert:notify-transition($transition, $workflow, $case, $activity, $transition/@Template, $transition/Recipients),
    <success>
      <done/>
      { $success/* }
    </success>
    )[last()]
  else
    $success
  )[last()]
};

(: ======================================================================
   Generates model to display a timeline view of the workflow
   Status may be a step or a state
   ======================================================================
:)
declare function workflow:gen-workflow-steps( $workflow as xs:string, $item as element(), $lang as xs:string ) {
  let $current-status := $item/StatusHistory/CurrentStatusRef
  let $concurrent-status := $item/StatusHistory/ConcurrentStatusRef
  let $workflow-def := globals:get-normative-selector-for(concat($workflow, 'WorkflowStatus'))
  return
    <Workflow>
      {(
      $workflow-def/@W,
      $workflow-def/@Offset,
      $workflow-def/@Name,
      for $s in $workflow-def/Option[not(@Deprecated)]
      let $ref := $s/Value/text()
      let $group := $s/@Group
      where empty($group) or ($s/@Type eq 'final') or empty($s/preceding-sibling::Option[@Group eq $group])
      return
        if ($s/@Type eq 'final') then
          if ($ref = ($current-status, $concurrent-status)) then
            <Step Display="state" Status="current" StartDate="{display:gen-display-date($item/StatusHistory/Status[ValueRef = $ref]/Date, $lang)}" Num="{$ref}"/>
          else
            <Step Display="state" StartDate="{display:gen-display-date($item/StatusHistory/Status[ValueRef = $ref]/Date, $lang)}" Num="{$ref}"/>
        else (: step :)
          let $flatten := if (exists($group)) then
                            let $elected := $item/StatusHistory/ConcurrentStatusRef[@Group eq $group]
                            return if ($workflow-def/Option[Value eq $elected]/@Type eq 'final') then () else $elected
                          else
                            $ref
          return
            if ($flatten) then
              <Step Display='step' StartDate="{display:gen-display-date($item/StatusHistory/Status[ValueRef = $flatten]/Date, $lang)}" Num="{$flatten}">
                {
                if ($flatten = ($current-status, $concurrent-status)) then
                  let $focus := $workflow-def/Option[Value eq $flatten]/@Focus
                  return
                    if (empty($focus) or ($focus ne 'none')) then
                      attribute { 'Status'} { 'current' }
                    else
                      ()
                else if ($s/@Type eq 'final') then 
                  attribute { 'Display'} { 'state' } 
                else 
                  ()
                }
              </Step>
            else
              ()
      )}
    </Workflow>
};

(: ======================================================================
   Generates the list of alerts associated to a workflow
   If the list can be completed dynamically (Ajax protocol) then the live 
   parameter must define its unique if.
   ======================================================================
:)
declare function workflow:gen-alerts-list ( $workflow as xs:string, $live as xs:string?, $item as element(), $prefixUrl as xs:string, $lang as xs:string ) as element()*
{
  <AlertsList Workflow="{$workflow}">
  {(
    if ($live) then attribute { 'Id' } { $live } else (),
    for $a in $item/Alerts/Alert
    order by number($a/Id) descending
    return workflow:gen-alert-for-viewing($workflow, $lang, $a, concat($prefixUrl, $item/No))
  )}
  </AlertsList>
};

(: ======================================================================
   Debug utility to generate an optional attribute Source with a link 
   to exist REST url of case XML model in dev mode only.
   Simple cases/YYYY/MM sharding.
   ====================================================================== 
:)
declare function workflow:gen-source ( $mode as xs:string, $case as element() ) as attribute()? {
  if ($mode eq 'dev') then
    attribute { 'Source' } { 
      let $call := $case/CreationDate/text()
      let $year := substring($call, 1, 4)
      let $month := substring($call, 6, 2)
      return concat('/exist/rest/db/sites/', globals:app-collection(), '/cases/', $year,'/', $month, '/', $case/No,'/case.xml')
    }
  else
    ()
};

declare function workflow:gen-new-activity-tab ( $case as element(), $activity as element()?, $prefixUrl as xs:string ) as element()? {
  if (access:check-document-permissions('create', 'Assignment', $case)) then
    <Tab Id="new-activity">
      <Name loc="workflow.tab.new.activity">Add</Name>
      <OnClick>
        <Command>
          <Name>confirm</Name>
          <Controller>{$prefixUrl}{globals:doc('application-uri')//Workflow[@Id eq 'Case']/Documents/Document[@Tab eq 'coaching-assignment']/Controller/text()}</Controller>
        </Command>
      </OnClick>
      <Heading class="case">
        <Title loc="workflow.title.new.activity">Add</Title>
      </Heading>
      <Legend>Click on the tab on the left to create a new coaching activity</Legend>
    </Tab>
  else
    ()
};

declare function workflow:gen-activities-tab ( $case as element(), $activity as element()?, $activities as element()*, $lang as xs:string ) as element() {
  <Tab Id="activities" Counter="Activity">
    <Name loc="workflow.tab.activities">Related activities</Name>
    <Heading class="case">
      <Title loc="workflow.title.activities">List of activities</Title>
    </Heading>
    <Activities>
      { 
      let $cur-status := $case/StatusHistory/CurrentStatusRef/text()
      return
        (
        if ($activity/No) then
          attribute { 'Current' } { $activity/No/text() }
        else
          (),
        if (empty($activities)) then
          if ($cur-status < "3") then  (: NOTE: string order as long as less than 9 states :)
            <Legend class="c-empty">This panel will show the list of coaching activities once the case workflow reaches the needs analysis status.</Legend>
          else
            <Legend class="c-empty">There is currently no on-going coaching activity for this case.</Legend>
        else
          $activities
        (:if (access:check-document-permissions('create', 'Assignment', $case)) then
                          <Add TargetModal="activity">
 <Template>../templates/coaching-assignment?goal=create&amp;n={$case-no}</Template>
                            <Controller>{$case-no}/assignment</Controller>
                            <Legend>Click on the button above to add a new Coaching activity and to assign a responsible Coach. Once you validate it the responsible Coach will receive an email asking him/her to prepare a coaching plan. <b>Before creating a Coaching activity you SHOULD complete the needs analysis document in the Case tab</b>, in particular to select the Business innovation challenges that will be used to configure the coaching activity.</Legend>                    
                          </Add>
                        else
                          ():)
        )
      }
    </Activities>
  </Tab>
};
