xquery version "1.0";
(: --------------------------------------
   XQuery Content Management Library

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Implementation of the XAL (XML Aggregation Language) language (see templates.xml)

   TODO: use XQuery exceptions to throw errors !

   April 2017 - (c) Copyright 2017 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

module namespace xal = "http://oppidoc.com/ns/xcm/xal";

declare namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../oppidum/lib/util.xqm";
import module namespace database = "http://oppidoc.com/ns/xcm/database" at "database.xqm";
import module namespace cache = "http://oppidoc.com/ns/xcm/cache" at "cache.xqm";

declare variable $xal:debug-uri := '/db/debug/xal.xml'; (: FIXME: move to globals :)
declare variable $xal:xal-actions := ('update', 'replace', 'insert', 'timestamp', 'create', 'invalidate', 'attribute', 'delete', 'remove', 'value', 'align', 'assert');

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
   Two behaviors: with a @Source attribute replaces the dereferenced source 
   with the provided fragment, with an @Update="value" attribute replaces 
   text content of the same name $subject element with the fragment text content
   if they are different does nothing otherwise
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
  else 
    let $legacy := $subject/*[local-name() eq local-name($fragment)]
    let $what := $xal-spec/@Update
    return
      if (exists($legacy)) then
        if (exists($what) and ($what eq 'value')) then
          if ($legacy/text() ne $fragment/text()) then
            update value $legacy with $fragment/text()
          else
            ()
        else (: full update :)
          update replace $legacy with $fragment
      else
        ()
};

(: ======================================================================
   XAL replace action implementation
   Returns the empty sequence
   LIMITATION: $fragment must match with a unique child of $subject
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
   LIMITATION: $fragment must match with a unique child of $subject
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
   XAL align action implementation
   Does a 'delete' on the child of the $subject with same name as fragment
   in case the fragment is empty
   Otherwise does a 'replace' on the $subject with the $fragment if it differs 
   or its children differ (when Check="children") from the $fragment 
   Does nothing otherwise
   Returns the empty sequence
   LIMITATION: $fragment must match with a unique child of $subject
   ====================================================================== 
:)
declare function local:apply-xal-align( $subject as element()?, $fragment as element(), $xal-spec as element() ) as element()? {
  if ($xal-spec/@Debug eq 'on') then
    update insert <XALInsert>{ $xal-spec/@*, $fragment }</XALInsert> into fn:doc($xal:debug-uri)/*[1]
  else
    (),
  if (exists($subject)) then
    let $legacy := $subject/*[local-name() eq local-name($fragment)]
    return
      if (empty($fragment) or $fragment eq '') then
        if (exists($legacy)) then 
          update delete $legacy
        else
          ()
      else if (empty($legacy)) then
        update insert $fragment into $subject
      else if ( (($xal-spec/@Check eq 'children') and fn:deep-equal($legacy/*, $fragment/*))
                or fn:deep-equal($legacy, $fragment) ) then
        ()
      else
        update replace $legacy with $fragment
  else
    ()
};

(: ======================================================================
   XAL assert action implementation
   Evaluates $fragment as an assertion and throws an oppidom error in case
   of wrong assertion of the empty sequence otherwise
   ====================================================================== 
:)
declare function local:apply-xal-assert( $subject as element()?, $fragment as element(), $xal-spec as element() ) as element()? {
  if ($xal-spec/@Debug eq 'on') then
    update insert <XALAssert>{ $xal-spec/@*, $fragment }</XALAssert> into fn:doc($xal:debug-uri)/*[1]
  else
    (),
  if (local-name($fragment) eq 'MaxLength') then
    let $limit := number($fragment/@Limit)
    let $length := string-length($fragment)
    return
      if ($length > $limit) then
        oppidum:throw-error($fragment/@Error, ($length, $length - $limit, $limit))
      else
        ()
  else if (local-name($fragment) eq 'True') then
    if ($fragment/text() eq 'true') then
      ()
    else
      oppidum:throw-error($fragment/@Error, ())
  else if (local-name($fragment) eq 'False') then
    if ($fragment/text() eq 'false') then
      ()
    else
      oppidum:throw-error($fragment/@Error, ())
  else
    oppidum:throw-error('XAL-UNKNOWN-ASSERTION', local-name($fragment))
};

(: ======================================================================
   XAL attribute action implementation
   Create or replaces the value of attribute Name only if the Value 
   is different
   Returns the empty sequence
   ====================================================================== 
:)
declare function local:apply-xal-attribute( $subject as element(), $xal-spec as element() ) as element()? {
  if ($xal-spec/@Debug eq 'on') then
    update insert $xal-spec into fn:doc($xal:debug-uri)/*[1]
  else
    (),
  let $name := string($xal-spec/@Name)
  let $value := $xal-spec/Value/text()
  let $legacy := $subject/@*[local-name() eq $name]
  return
    if (exists($legacy) and ($legacy ne $value)) then
      update value $legacy with $value
    else
      update insert attribute { $name } { $value } into $subject
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
  let $db := oppidum:get-command()/@db
  let $entity := database:get-entity-for($xal-spec/@Entity)
  return
    if (exists($entity/Collection/@Sharding) or contains($entity/Resource, '$_')) then
      database:create-entity-for-key($db, $xal-spec/@Entity, $xal-spec/*, $xal-spec/@Key)
    else
      let $created := database:create-entity($db, $xal-spec/@Entity, $xal-spec/*)
      return
        if (empty($created)) then
          (: TODO: also return resource path :)
          <success type="create" key="{ $xal-spec/@Key }"/>
        else
          $created
};

(: ======================================================================
   XAL invalidate action to invalidate a cache entry
   ====================================================================== 
:)
declare function local:apply-xal-invalidate( $xal-spec as element() ) {
  if ($xal-spec/@Debug eq 'on') then
    update insert $xal-spec into fn:doc($xal:debug-uri)/*[1]
  else
    (),
  for $entry in $xal-spec/Cache
  return cache:invalidate($entry, $xal-spec/@Lang)
};

(: ======================================================================
   XAL delete action to delete the subject
   ====================================================================== 
:)
declare function local:apply-xal-delete( $subject as element()?, $xal-spec as element() ) {
  if ($xal-spec/@Debug eq 'on') then
    update insert $xal-spec into fn:doc($xal:debug-uri)/*[1]
  else
    (),
  update delete $subject
};

(: ======================================================================
   XAL remove action to remove a resource from the database
   Locates resource by @Key / entity name within database.xml
   e.G. <XALAction Type="remove" Key="3567">persons</XALAction>
   FIXME: finish, file name should be generated (actually assumes $_.xml)
   ====================================================================== 
:)
declare function local:apply-xal-remove( $subject as element()?, $xal-spec as element() ) {
  if ($xal-spec/@Debug eq 'on') then
    update insert $xal-spec into fn:doc($xal:debug-uri)/*[1]
  else
    (),
  let $key := $xal-spec/@Key
  let $cmd := oppidum:get-command()
  return
    if ($key and ($xal-spec ne '')) then
      let $col-uri := database:gen-collection-for-key (concat($cmd/@db,'/'), $xal-spec, $key)
      let $filename := concat($key, '.xml') (: FIXME: database:gen-resource-for-key ? :)
      return 
        if (local-name($col-uri) eq 'success') then 
          if (fn:doc-available(concat($col-uri, '/', $filename))) then
            xdb:remove($col-uri, $filename)
          else
            oppidum:throw-error('CUSTOM', concat('Document ', concat($col-uri, '/', $filename), ' not found in XAL remove action'))
        else
          $col-uri
    else
      oppidum:throw-error('CUSTOM', 'Missing Key or entity name in XAL remove action')
};

(: ======================================================================
   XAL value action implementation
   Creates or replaces the value of subject with the text content of the XAL
   action if it is different
   Returns the empty sequence
   ====================================================================== 
:)
declare function local:apply-xal-value( $subject as element(), $xal-spec as element() ) as element()? {
  if ($xal-spec/@Debug eq 'on') then
    update insert $xal-spec into fn:doc($xal:debug-uri)/*[1]
  else
    (),
  let $value := string($xal-spec)
  return
    if ($subject ne $value) then
      update value $subject with $value
    else
      ()
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
          if ($type eq 'create') then (: atomic 1 fragment action - TODO: check cardinality :)
            local:apply-xal-create($pivot, $action)
          else if ($type eq 'timestamp') then
            local:apply-xal-timestamp($pivot, $action)
          else if ($type eq 'attribute') then
            local:apply-xal-attribute($pivot, $action)
          else if (($type eq 'invalidate') and (empty($spec/@Mode) or ($spec/@Mode ne 'batch'))) then
            local:apply-xal-invalidate($action)
          else if ($type eq 'delete') then
            local:apply-xal-delete($pivot, $action)
          else if ($type eq 'remove') then
            local:apply-xal-remove($pivot, $action)
          else if ($type eq 'value') then
            local:apply-xal-value($pivot, $action)
          else (: iterated actions on 1 or more fragments :)
            for $fragment in $action/*
            return
              if ($type eq 'replace') then
                local:apply-xal-replace($pivot, $fragment, $action)
              else if ($type eq 'update') then
                local:apply-xal-update($pivot, $fragment, $action)
              else if ($type eq 'insert') then
                local:apply-xal-insert($pivot, $fragment, $action)
              else if ($type eq 'align') then
                local:apply-xal-align($pivot, $fragment, $action)
              else if ($type eq 'assert') then
                local:apply-xal-assert($pivot, $fragment, $action)
              else
                ()
    return
      if (empty($res)) then
        <success/>
      else
        $res[last()]
    )
  else
    let $mismatch := distinct-values($spec/XALAction/@Type[not(. = $xal:xal-actions)])
    return oppidum:throw-error('XAL-UNKNOWN-ACTION', string-join($mismatch, ', '))
};

