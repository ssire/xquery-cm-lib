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

declare variable $xal:debug-uri := '/db/sites/debug/xal.xml'; (: FIXME: move to globals :)
declare variable $xal:xal-actions := ('update', 'replace', 'insert', 'timestamp', 'create');

(: ======================================================================
   Filters nodes and evaluates <node>{ "expression" }</node> type nodes
   Used to evaluate xal:auto-increment in data-templates that contains
   <Id>{{ xal:auto-increment($subject, 'LastIndex') }}</Id>
   ====================================================================== 
:)
declare function local:auto-eval( $subject as element()?, $nodes as item()* ) as item()* {
  for $node in $nodes
  return
    typeswitch($node)
      case text()
        return 
            if (matches($node,'\{.*\}')) then
              util:eval(substring-after(substring-before($node, '}' ), '{'))
            else
              $node
      case attribute()
        return $node
      case element()
        return
            element { local-name($node) } { $node/attribute(), local:auto-eval($subject, $node/node()) }
      default
        return $node
};

(: ======================================================================
   Generates an index using a local attribute containing a last index
   on the subject. Returns the index or the empty sequence and throws 
   an Oppidum error in case of failure.
   ====================================================================== 
:)
declare function xal:auto-increment( $subject as element()?, $name as xs:string ) as xs:string? {
  if ($subject/@*[local-name() eq $name]) then
    let $cur := $subject/@*[local-name() eq $name]
    let $next := 
      if ($cur castable as xs:integer) then
        string(xs:integer($cur) + 1)
      else
        '1'
    return (
      update value $cur with $next,
      $next
      )
  else if ($subject) then (
    update insert attribute { $name } { '1' } into $subject,
    '1'
    )
  else 
    let $err := oppidum:throw-error('CUSTOM', 'xal:auto-increment $subject not found')
    return ()
};

(: ======================================================================
   XAL update action implementation
   Pre-condition: @Source available
   Returns the empty sequence
   ====================================================================== 
:)
declare function local:apply-xal-update( $subject as element(), $fragment as element(), $xal-spec as element() ) as element()? {
  if ($xal-spec/@Debug eq 'on') then
    update insert <XALUpdate>{ $xal-spec/@*, $fragment }</XALUpdate> into fn:doc($xal:debug-uri)/*[1]
  else
    (),
  if ($xal-spec/@Source) then
    let $legacy := util:eval($xal-spec/@Source)
    return
      update replace $legacy with $fragment
  else (: should we report an error :)
    ()
};

(: ======================================================================
   XAL replace action implementation
   Returns the empty sequence
   ====================================================================== 
:)
declare function local:apply-xal-replace( $subject as element(), $fragment as element(), $xal-spec as element() ) as element()? {
  if ($xal-spec/@Debug eq 'on') then
    update insert <XALReplace>{ $xal-spec/@*, $fragment }</XALReplace> into fn:doc($xal:debug-uri)/*[1]
  else
    (),
  let $legacy := $subject/*[local-name(.) eq local-name($fragment)]
  return
    if (exists($legacy)) then
      update replace $legacy with $fragment
    else
      update insert $fragment into $subject
};

(: ======================================================================
   XAL insert action implementation
   Returns the empty sequence
   TODO: version with parent hierarchy lazy creation ?
   ====================================================================== 
:)
declare function local:apply-xal-insert( $subject as element()?, $fragment as element(), $xal-spec as element() ) as element()? {
  if ($xal-spec/@Debug eq 'on') then
    update insert <XALInsert>{ $xal-spec/@*, $fragment }</XALInsert> into fn:doc($xal:debug-uri)/*[1]
  else
    (),
  if (exists($subject)) then
    if (contains(string($fragment), '{')) then 
      update insert local:auto-eval($subject, $fragment) into $subject
    else
      update insert $fragment into $subject
  else
    ()
};

(: ======================================================================
   XAL timestamp action implementation
   Adds or updates a timestamp to the parent using $name attribute
   Returns the empty sequence
   TODO: throw oppidum exception if empty $subject (?)
   ====================================================================== 
:)
declare function local:apply-xal-timestamp( $subject as element()?, $xal-spec as element() ) {
  if ($xal-spec/@Debug eq 'on') then
    update insert $xal-spec into fn:doc($xal:debug-uri)/*[1]
  else
    (),
  let $name := string($xal-spec)
  return
    if (exists($subject)) then
      let $date := current-dateTime()
      let $ts := $subject/@*[local-name(.) eq $name]
      return
        if (exists($ts)) then
          update value $ts with $date
        else
          update insert attribute { $name } { $date } into $subject
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
declare function local:apply-xal-create( $subject as element()?, $xal-spec as element() ) as element() {
  if ($xal-spec/@Debug eq 'on') then
    update insert $xal-spec into fn:doc($xal:debug-uri)/*[1]
  else
    (),
  database:create-entity-for-key(oppidum:get-command()/@db, $xal-spec/@Entity, $xal-spec/*, $xal-spec/@Key)
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
   Returns the latest <success/> in case of success (generates an empty <success/> in case 
   of success without any explicit <success/> generated) or the latest <error/>

   TODO: use XQuery exceptions inside each XALAction and stops on first error ?
   ====================================================================== 
:)
declare function xal:apply-updates( $subject as item()*, $object as item()*, $spec as element()? ) as element() {
  if ($spec/@Debug eq 'on') then
    update insert <XALApply Date="{ current-dateTime() }">{ $spec }</XALApply> into fn:doc($xal:debug-uri)/*[1]
  else
    (),
  if (every $fragment in $spec/XALAction satisfies $fragment/@Type = $xal:xal-actions) then (: sanity check :) 
    (
    if (exists($spec/XALAction[@Debug eq 'on'])) then
      update insert <Processing Date="{ current-dateTime() }">xal:apply-updates processing { count($spec/XALAction) } actions</Processing> into fn:doc($xal:debug-uri)/*[1]
    else
      (),
    let $res :=
      for $action in $spec/XALAction
      let $type := $action/@Type
      let $pivot := if (exists($action/@Pivot)) then util:eval(string($action/@Pivot)) else $subject
      return
        if (count($pivot) > 1) then
          oppidum:throw-error('XAL-PIVOT-ERROR', (string($action/@Pivot), count($pivot)))
        else
          if ($action/@Type eq 'create') then (: atomic 1 fragment action - TODO: check cardinality :)
            local:apply-xal-create($pivot, $action)
          else if ($action/@Type eq 'timestamp') then
            local:apply-xal-timestamp($pivot, $action)
          else (: iterated actions on 1 or more fragments :)
            for $fragment in $action/*
            return
              if ($type eq 'replace') then
                local:apply-xal-replace($pivot, $fragment, $action)
              else if ($type eq 'update') then
                local:apply-xal-update($pivot, $fragment, $action)
              else if ($type eq 'insert') then
                local:apply-xal-insert($pivot, $fragment, $action)
              else
                ()
    return
      if (empty($res)) then
        <success/>
      else
        $res[last()]
    )
  else
    oppidum:throw-error('XAL-UNKOWN-ACTION', $spec/XALAction/@Type[not(. = $xal:xal-actions)])
};

