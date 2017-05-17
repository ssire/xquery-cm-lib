xquery version "1.0";
(: --------------------------------------
   XQuery Content Management Library

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Implementation of the XAL (XML Aggregation Language) language (see templates.xml)

   TODO: use XQuery exceptions to throw errors !

   April 2017 - (c) Copyright 2017 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

module namespace xal = "http://oppidoc.com/ns/xcm/xal";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../oppidum/lib/util.xqm";
import module namespace database = "http://oppidoc.com/ns/xcm/database" at "database.xqm";

declare variable $xal:xal-actions := ('replace', 'insert', 'timestamp', 'create');

(: ======================================================================
   XAL replace action implementation
   Returns the empty sequence
   ====================================================================== 
:)
declare function local:apply-xal-replace( $parent as element(), $fragment as element() ) as element()? {
  let $legacy := $parent/*[local-name(.) eq local-name($fragment)]
  return
    if (exists($legacy)) then
      update replace $legacy with $fragment
    else
      update insert $fragment into $parent
};

(: ======================================================================
   XAL insert action implementation
   Returns the empty sequence
   TODO: version with parent hierarchy lazy creation ?
   ====================================================================== 
:)
declare function local:apply-xal-insert( $parent as element()?, $fragment as element() ) as element()? {
  if (exists($parent)) then
    update insert $fragment into $parent
  else
    ()
};

(: ======================================================================
   XAL timestamp action implementation
   Adds or updates a timestamp to the parent using $name attribute
   Returns the empty sequence
   TODO: throw oppidum exception if empty $parent (?)
   ====================================================================== 
:)
declare function local:apply-xal-timestamp( $parent as element()?, $xal-timestamp-spec as element()  ) {
  let $name := string($xal-timestamp-spec)
  return
    if (exists($parent)) then
      let $date := current-dateTime()
      let $ts := $parent/@*[local-name(.) eq $name]
      return
        if (exists($ts)) then
          update value $ts with $date
        else
          update insert attribute { $name } { $date } into $parent
    else
      ()
};

(: ======================================================================
   XAL timestamp create action implementation
   Adds a new document to the database using database module and database.xml
   Returns a <success/> element or throws an Oppidum error
   TODO: throw error if missing @Entity or @Key
   ====================================================================== 
:)
declare function local:apply-xal-create( $parent as element()?, $xal-create-spec as element() ) as element() {
  database:create-entity-for-key(oppidum:get-command()/@db, $xal-create-spec/@Entity, $xal-create-spec/*, $xal-create-spec/@Key)
};

(: =======================================================================
   Implements XAL (XML Aggregation Language) update protocol
   Basic version for single container element update
   =======================================================================
:)
declare function xal:apply-updates( $subject as element(), $spec as element() ) as element() {
  xal:apply-updates($subject, (), $spec)
};

(: ======================================================================
   Implements XAL (XML Aggregation Language) update protocol
   Subject - Object version for dual container element upate (e.g. to maintain references)
   Supports the Pivot attribute
   Stops on first reported <error/> and return the <error/> element in case of an error
   but it does not do any rollback 
   Returns the latest <success/> in case of success (generates an empty <success/> in case 
   of success without any explicit <success/> generated)
   ====================================================================== 
:)
declare function xal:apply-updates( $subject as item()*, $object as item()*, $spec as element() ) as element() {
  if (every $fragment in $spec/XALAction satisfies $fragment/@Type = $xal:xal-actions) then (: sanity check :)
    let $res := xal:apply-updates-iter((), $subject, $object, $spec/XALAction, ())
    return
      if (empty($res)) then
        <success/>
      else
        $res[last()]
  else
    oppidum:throw-error('XAL-UNKOWN-ACTION', $spec/XALAction/@Type[not(. = $xal:xal-actions)])
};

(: ======================================================================
   Implementation
   ====================================================================== 
:)
declare function xal:apply-updates-iter( 
  $pivot as element()?, 
  $subject as item()*, 
  $object as item()*, 
  $actions as element()*, 
  $accu as element()* ) as element()* 
{
  (: stops on <error/> collapses <success/> to keep only latest :)
  if (empty($actions) or (local-name($accu[last()]) eq 'error')) then 
    $accu
  else
    let $cur := $actions[1]
    let $pivot := if (exists($cur/@Pivot)) then util:eval(string($cur/@Pivot)) else $subject
    return
      xal:apply-updates-iter(
        $pivot,
        $subject, 
        $object, 
        subsequence($actions, 2), 
        ($accu, xal:apply-xal-action($pivot, $subject, $object, $cur))
        )
};

(: ======================================================================
   Implementation
   ====================================================================== 
:)
declare function xal:apply-xal-action( $pivot as element()?, $subject as item()*, $object as item()*, $action as element() ) as element()* {
  if ($action/@Type eq 'create') then (: atomic 1 fragment action - TODO: check cardinality :)
    local:apply-xal-create($pivot, $action)
  else if ($action/@Type eq 'timestamp') then
    local:apply-xal-timestamp($pivot, $action)
  else (: iterated actions on 1 or more fragments :)
    xal:apply-xal-action-iter($action/@Type, $pivot, $subject, $object, $action/*, ())
};

(: ======================================================================
   Implementation
   ====================================================================== 
:)
declare function xal:apply-xal-action-iter( 
  $type as xs:string, 
  $pivot as element()?, 
  $subject as item()*, 
  $object as item()*, 
  $fragments as element()*, 
  $accu as element()* ) as element()* 
{
  (: stops on <error/> collapses <success/> to keep only latest :)
  if (empty($fragments) or (local-name($accu[last()]) eq 'error')) then 
    $accu
  else 
    let $cur := $fragments[1]
    return
      xal:apply-xal-action-iter( 
        $type,
        $pivot,
        $subject,
        $object,
        subsequence($fragments, 2), 
        ($accu,
        if ($type eq 'replace') then
          local:apply-xal-replace($pivot, $cur)
        else if ($type eq 'insert') then
          local:apply-xal-insert($pivot, $cur)
        else
          ()
        )
        )
};
