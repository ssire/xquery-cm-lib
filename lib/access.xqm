xquery version "1.0";
(: --------------------------------------
   XQuery Content Management Library

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Access control functions
   Implements access control micro-language in application.xml

   Can be used :
   - to control display of command buttons in the user interface
   - fine grain access to CRUD controllers

   Conventions :
   - assert:check-* : high-level boolean functions to perform a check
   - access:assert-* : low-level interpretor functions

   Do not forget to also set mapping level <access> rules to prevent URL forgery !

   November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)
module namespace access = "http://oppidoc.com/ns/xcm/access";

declare namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "globals.xqm";
import module namespace user = "http://oppidoc.com/ns/xcm/user" at "user.xqm";

(: ======================================================================
   Interprets Omnipotent Allow access control rule (see application.xml)
   Returns true if current user is allowed to do anything
   ======================================================================
:)
declare function access:check-omnipotent-user() as xs:boolean {
  let $security-model := globals:doc('application-uri')/Application/Security
  let $rules := $security-model/Omnipotent
  let $user := oppidum:get-current-user()
  let $groups := oppidum:get-current-user-groups()
  return
    (empty($rules/Meet) or (some $rule in $rules/Meet satisfies access:assert-rule($user, $groups, $rule, ())))
    and
    (empty($rules/Avoid) or not(some $rule in $rules/Avoid satisfies access:assert-rule($user, $groups, $rule, ())))
};

(: ======================================================================
   Returns true() if the user profile is omniscient (i.e. can see everything)
   ======================================================================
:)
declare function access:check-omniscient-user( $profile as element()? ) as xs:boolean {
  some $function-ref in $profile//FunctionRef
  satisfies $function-ref = globals:get-normative-selector-for('Functions')/Option[@Sight = 'omni']/Value
};

(: ======================================================================
   Implements Allow access control rules
   Currently limited to comma separated list of g:token
   TODO: implement u:* and s:omni
   ======================================================================
:)
declare function access:check-rule( $rule as xs:string? ) as xs:boolean {
  if (empty($rule) or ($rule eq '')) then
    true()
  else
    let $user := oppidum:get-current-user()
    let $groups := oppidum:get-current-user-groups()
    let $allowed := tokenize($rule,"\s*g:")[. ne '']
    return
        if ($groups = $allowed) then
          true()
        else
          access:check-rules($user, $allowed)
};

(: ======================================================================
   Checks user has at least one of the given roles
   ======================================================================
:)
declare function access:check-rules( $user as xs:string, $roles as xs:string* ) as xs:boolean {
  some $ref in globals:collection('global-info-uri')//Description[@Role = 'normative']//Selector[@Name eq 'Functions']/Option[@Role = $roles]/Value
  satisfies globals:collection('persons-uri')//Person/UserProfile[Username eq $user]//FunctionRef = $ref
};

(: ======================================================================
   Interprets sight role token from role specificiation micro-language
   Sight defines an transversal roles independent of context
   ======================================================================
:)
declare function access:assert-sight( 
  $suffix as xs:string 
  ) as xs:boolean 
{
  let $groups-ref := globals:collection('global-info-uri')//Description[@Role = 'normative']/Selector[@Name eq 'Functions']/Option[@Sight eq $suffix]/Value
  let $user-profile := user:get-user-profile()
  return
    $user-profile//FunctionRef = $groups-ref
};

(: ======================================================================
   Stub function to call access:assert-access-rules w/o object
   DEPRECATED: you should call a access:check-*-permissions function 
   ======================================================================
:)
declare function access:assert-access-rules( $rules as element()?, $subject as element()? ) as xs:boolean
{
  access:assert-access-rules($rules, $subject, ())
};

(: ======================================================================
   Interprets access control rules micro-language (Meet | Avoid)* against 
   a subject and an object. 
   DEPRECATED: implementation function that should move to local: prefix
   You should call a access:check-*-permissions function.
   @return An xs:boolean
   ======================================================================
:)
declare function access:assert-access-rules( 
  $rules as element()?, 
  $subject as element()?, 
  $object as element()? 
  ) as xs:boolean 
{
  if (empty($rules)) then
    if ($rules/@Type = 'read') then (: enabled by default, mapping level should block non member users :)
      true()
    else (: any other action requires an explicit rule :)
      false()
  else
    let $user := oppidum:get-current-user()
    let $groups := oppidum:get-current-user-groups()
    return
      if (empty($rules/Meet[@Policy eq 'strict']) and access:check-omnipotent-user()) then
        true()
      else
        (empty($rules/Meet) or (some $rule in $rules/Meet satisfies access:assert-rule($user, $groups, $rule, $subject, $object)))
        and
        (empty($rules/Avoid) or not(some $rule in $rules/Avoid satisfies access:assert-rule($user, $groups, $rule, $subject, $object)))
        and
        (exists($rules/Meet) or exists($rules/Avoid))
};

(: ======================================================================
   Stub function to call access:assert-rule w/o object
   ======================================================================
:)
declare function access:assert-rule( 
  $user as xs:string, 
  $groups as xs:string*, 
  $rule as element(), 
  $subject as element()? 
  ) as xs:boolean 
{
  access:assert-rule($user, $groups, $rule, $subject, ())
};

(: ======================================================================
   Returns true if any of the token role definition from the rule
   yields for current user, groups, case, optional activity
   ======================================================================
:)
declare function access:assert-rule( 
  $user as xs:string, 
  $groups as xs:string*, 
  $rule as element(), 
  $subject as element()?, 
  $object as element()? 
  ) as xs:boolean 
{
  if ($rule/@Format eq 'eval') then
    util:eval($rule/text())
  else
    some $token in tokenize($rule, " ")
      satisfies
        let $prefix := substring-before($token, ':')
        let $suffix := substring-after($token, ':')
        return
          (($prefix eq 'u') and ($user eq $suffix))
          or (($prefix eq 'g') and ($groups = $suffix))
          or (($prefix eq 'r') and access:assert-semantic-role($suffix, $subject, $object))
          or (($prefix eq 's') and access:assert-sight($suffix)) (: FIXME: actually only 'omni' sight :)
          or false()
};

(: ======================================================================
   Tests current user is compatible with semantic role given as parameter

   See also default email recipients list generation in workflow/alert.xql

   FIXME: should we complete $subject and $object with $profile 
   and get $profile from caller to factorize calls to user:get-user-profile() ?
   ======================================================================
:)
declare function access:assert-semantic-role( $suffix as xs:string, $subject as element()?, $object as element()? ) as xs:boolean {
  let $uid := user:get-current-person-id() 
  return
    if ($uid) then
      let $role := globals:doc('application-uri')/Application/Security/Roles/Role[@Name eq $suffix]/Meet
      return
        if ($role) then
          util:eval($role)
        else
          false()
    else
      false()
};

(: ======================================================================
   Tests access control model against a given action
   Context independent version
   DEPRECATED use check-*-permissions instead
   ======================================================================
:)
declare function access:assert-user-role-for( $action as xs:string, $control as element()? ) as xs:boolean {
  let $rules := $control/Action[@Type eq $action]
  return
    if (empty($rules)) then
      if ($action = 'read') then (: enabled by default, mapping level should block non member users :)
        true()
      else (: any other action requires an explicit rule :)
        false()
    else
      access:assert-access-rules($rules, ())
};

(: ======================================================================
   Tests access control model against a given action on a given case or activity for current user
   Returns a boolean
   DEPRECATED use check-*-permissions instead
   ======================================================================
:)
declare function access:assert-user-role-for( $action as xs:string, $control as element()?, $subject as element(), $object as element()? ) {
  let $rules := $control/Action[@Type eq $action]
  return
    if (empty($rules)) then
      if ($action = 'read') then (: enabled by default, mapping level should block non membres of users :)
        true()
      else (: any other action requires an explicit rule :)
        false()
    else
      access:assert-access-rules($rules, $subject, $object)
};

(: ======================================================================
   Tests access control model against a given action on a given worklow actually in cur status
   Returns true if workflow status compatible with action, false otherwise
   See also workflow:gen-information in worklow/workflow.xqm
   TODO: move to workflow.xqm ?
   ======================================================================
:)
declare function access:assert-workflow-state( $action as xs:string, $workflow as xs:string, $control as element(), $cur as xs:string ) as xs:boolean {
  let $rule :=
    if ($control/@TabRef) then (: main document on accordion tab :)
      globals:doc('application-uri')//Workflow[@Id eq $workflow]/Documents/Document[@Tab eq string($control/@TabRef)]/Action[@Type eq $action]
    else (: satellite document in modal window :)
      let $host := globals:doc('application-uri')//Workflow[@Id eq $workflow]//Host[@RootRef eq string($control/@Root)]
      return
        if ($host/Action[@Type eq $action]) then
          $host/Action[@Type eq $action]
        else
          $host/parent::Document/Action[@Type eq $action]
  return
    empty($rule)
      or $rule[$cur = tokenize(string(@AtStatus), " ")]
};

(: ======================================================================
   Asserts case data is compatible with transition
   This can be used to suggest transition to user or to prevent it
   TODO: move to workflow.xqm ?
   ======================================================================
:)
declare function access:assert-transition( $from as xs:string, $to as xs:string, $case as element(), $activity as element()? ) as xs:boolean {
  let $workflow := if ($activity) then 'Activity' else 'Case'
  let $transition := globals:doc('application-uri')//Workflow[@Id eq $workflow]//Transition[@From eq $from][@To eq $to]
  return access:assert-transition($transition, $case, $activity)
};

(: ======================================================================
   Implements Assert element on Transition element from application.xml
   First checks current status compatibility with transition
   TODO: move to workflow.xqm ?
   ====================================================================== 
:)
declare function access:assert-transition( $transition as element()?, $case as element(), $activity as element()? ) as xs:boolean {
  let $item := if ($activity) then $activity else $case
  return
    if ($transition and ($item/StatusHistory/CurrentStatusRef eq string($transition/@From))) then
      every $check in 
        for $assert in $transition/Assert
        let $base := util:eval($assert/@Base)
        return
          let $rules := $assert/true
          return 
            if (count($rules) > 0) then
              every $expr in $rules satisfies util:eval($expr/text())
            else 
              false()
      satisfies $check 
    else
      false()
};

(: ======================================================================
   Implements one specific Assert element on Transition element from application.xml
   for item which may be a Case or an Activity
   Checks first current status compatibility with transition
   TODO: merge with access:assert-transition ???
   ====================================================================== 
:)
declare function access:assert-transition-partly( $item as element(), $assert as element()?, $subject as element()?) as xs:boolean {
  let $transition := $assert/parent::Transition
  return
    if ($transition and ($item/StatusHistory/CurrentStatusRef eq string($transition/@From))) then
      let $rules := $assert/true
      let $base := $subject
      return 
        if (count($rules) > 0) then
          every $expr in $rules satisfies util:eval($expr/text())
        else 
          false()
    else
      false()
};

(: ======================================================================
   Returns true if the transition is allowed for case or activity for current user,
   or false otherwise
   Pre-condition :
   YOU MUST obtain the transition by a call to workflow:get-transition-for() to be sure
   the transition is feasible from the current state, otherwise you will not be able
   to interpret the false result
   TODO: move to workflow.xqm ?
   ======================================================================
:)
declare function access:check-status-change( $transition as element(), $subject as element(), $activity as element()? ) as xs:boolean {
  let $status :=
    if ($activity) then
      $activity/StatusHistory/CurrentStatusRef/text()
    else
      $subject/StatusHistory/CurrentStatusRef/text()
  return
    if ($transition/@From = $status) then (: see pre-condition :)
      access:assert-access-rules($transition, $subject, $activity)
    else
      false()
};

(: ======================================================================
   Implements access control rules in Resources element of application.xml
   Checks $action is allowed on resource $type
   Interprets semantic rules against a $subject element (optional)
   ======================================================================
:)
declare function access:check-entity-permissions( $action as xs:string, $type as xs:string, $subject as element()?, $object as element()? ) as xs:boolean 
{
  let $security-model := fn:doc(oppidum:path-to-config('application.xml'))//Security/Resources/Resource[@Name = $type]
  let $rules := $security-model/Action[@Type eq $action]
  return
    access:assert-access-rules($rules, $subject, $object)
};

(: ======================================================================
   Stub function to call access:check-entity-permissions w/o object
   ====================================================================== 
:)
declare function access:check-entity-permissions( $action as xs:string, $type as xs:string, $subject as element()? ) as xs:boolean 
{
  access:check-entity-permissions($action, $type, $subject, ())
};

(: ======================================================================
   Stub function to call access:check-entity-permissions w/o subject
   ====================================================================== 
:)
declare function access:check-entity-permissions( $action as xs:string, $type as xs:string ) as xs:boolean 
{
  access:check-entity-permissions($action, $type, (), ())
};

(: ======================================================================
   Implements access control rules in Documents element of application.xml
   Checks $action is allowed on document with root $root
   Interprets semantic rules against $subject and $object elements
   ======================================================================
:)
declare function access:check-document-permissions( $action as xs:string, $root as xs:string, $subject as element()?, $object as element()? ) as xs:boolean
{
  let $security-model := fn:doc(oppidum:path-to-config('application.xml'))//Security/Documents/Document[@Root = $root]
  let $rules := $security-model/Action[@Type eq $action]
  return
    access:assert-access-rules($rules, $subject, $object)
};

(: ======================================================================
   Stub function to call access:check-document-permissions w/o object
   ====================================================================== 
:)
declare function access:check-document-permissions( $action as xs:string, $root as xs:string, $subject as element()? ) as xs:boolean
{
  access:check-document-permissions($action, $root, $subject, ())
};

(: ======================================================================
   Implements access control rules in Documents element of application.xml
   Checks $action is allowed on document in tab $tab
   Interprets semantic rules against $subject and $object elements
   ======================================================================
:)
declare function access:check-tab-permissions( $action as xs:string, $tab as xs:string, $subject as element()?, $object as element()? ) as xs:boolean 
{
  let $security-model := fn:doc(oppidum:path-to-config('application.xml'))//Security/Documents/Document[@TabRef = $tab]
  let $rules := $security-model/Action[@Type eq $action]
  return
    access:assert-access-rules($rules, $subject, $object)
};

(: ======================================================================
   Stub function to call access:check-tab-permissions w/o object
   ====================================================================== 
:)
declare function access:check-tab-permissions( $action as xs:string, $tab as xs:string, $subject as element()? ) as xs:boolean 
{
  access:check-tab-permissions($action, $tab, $subject, ())
};

(: ======================================================================
   Implements access control rules in Workflow element of application.xml
   Checks $action is allowed in workflow $workflow on document with root $root
   Interprets semantic rules against optional $subject and $object elements 
   (typically a Case and an Activity) using $object as first choice 
   when it is defined and has a StatusHistory or $subject otherwise 
   to assert compatibility with current workflow status
   ======================================================================
:)
declare function access:check-workflow-permissions( $action as xs:string, $workflow as xs:string, $root as xs:string, $subject as element()?, $object as element()? ) as xs:boolean 
{
  let $security-model := fn:doc(oppidum:path-to-config('application.xml'))//Security/Documents/Document[@Root = $root]
  let $rules := $security-model/Action[@Type eq $action]
  return
    if (access:assert-user-role-for($action, $security-model, $subject, $object)) then
      if (exists($object/StatusHistory/CurrentStatusRef)) then
        access:assert-workflow-state($action, $workflow, $security-model, $object/StatusHistory/CurrentStatusRef)
      else if (exists($subject/StatusHistory/CurrentStatusRef)) then 
        access:assert-workflow-state($action, $workflow, $security-model, $subject/StatusHistory/CurrentStatusRef)
      else (: FIXME: throw exception :)
        false()
    else
      false()
};

(: ======================================================================
   Stub function to call access:check-workflow-permissions w/o object
   ====================================================================== 
:)
declare function access:check-workflow-permissions( $action as xs:string, $workflow as xs:string, $root as xs:string, $subject as element()? ) as xs:boolean 
{
  access:check-workflow-permissions($action, $workflow, $root, $subject, ())
};

(: ======================================================================
   Stub function to call access:check-entity-permissions and to raise 
   appropriate oppidum errors when necessary
   ====================================================================== 
:)
declare function access:get-entity-permissions( $action as xs:string, $type as xs:string, $subject as element()? ) as element()
{
  if (empty($subject)) then
    oppidum:throw-error('URI-NOT-FOUND', ())
  else if (access:check-entity-permissions($action, $type, $subject, ())) then
    <allow/>
  else
    oppidum:throw-error('FORBIDDEN', ())
};

(: ======================================================================
   Stub function to call access:check-entity-permissions and to raise 
   appropriate oppidum errors when necessary
   ====================================================================== 
:)
declare function access:get-entity-permissions( $action as xs:string, $type as xs:string, $subject as element()?, $object as element()? ) as element()
{
  if (empty($subject) or empty($object)) then
    oppidum:throw-error('URI-NOT-FOUND', ())
  else if (access:check-entity-permissions($action, $type, $subject, $object)) then
    <allow/>
  else
    oppidum:throw-error('FORBIDDEN', ())
};

(: ======================================================================
   Stub function to call access:get-tab-permissions and to raise 
   appropriate oppidum errors when necessary
   ======================================================================
:)
declare function access:get-tab-permissions( $action as xs:string, $tab as xs:string, $subject as element()? ) as  element()
{
  if (empty($subject)) then
    oppidum:throw-error('URI-NOT-FOUND', ())
  else if (access:check-tab-permissions($action, $tab, $subject, ())) then
    <allow/>
  else
    oppidum:throw-error('FORBIDDEN', ())
};
