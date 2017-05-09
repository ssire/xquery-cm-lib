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

declare variable $xal:xal-actions := ('replace');
declare variable $xal:xal-pivot-actions := ('replace', 'insert', 'timestamp');

(: ======================================================================
   XAL replace action implementation
   ====================================================================== 
:)
declare function local:apply-xal-replace( $parent as element(), $fragment as element() ) {
  let $legacy := $parent/*[local-name(.) eq local-name($fragment)]
  return
    if (exists($legacy)) then
      update replace $legacy with $fragment
    else
      update insert $fragment into $parent
};

(: ======================================================================
   XAL insert action implementation
   TODO: throw exception if empty $parent
   ====================================================================== 
:)
declare function local:apply-xal-insert( $parent as element()?, $fragment as element() ) {
  if (exists($parent)) then
    update insert $fragment into $parent
  else
    ()
};

(: ======================================================================
   XAL timestamp action implementation
   Adds or updates a timestamp to the parent using $name attribute
   TODO: throw exception if empty $parent
   ====================================================================== 
:)
declare function local:apply-xal-timestamp( $parent as element()?, $fragment as element(), $name as xs:string ) {
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

(: =======================================================================
   Implements XAL (XML Aggregation Language) update protocol
   Basic version for single container element update
   Throws an Oppdum error if some action is not implemented
   TODO: supports the Pivot element ?
   =======================================================================
:)
declare function xal:apply-updates( $parent as element(), $spec as element() ) {
  if (every $fragment in $spec/XALAction satisfies $fragment/@Type = $xal:xal-actions) then (: sanity check :)
    for $fragment in $spec/XALAction
    return
      if ($fragment/@Type eq 'replace') then
        for $cur in $fragment/*
        return local:apply-xal-replace($parent, $cur)
      else
        ()
  else
    oppidum:throw-error('XAL-UNKOWN-ACTION', $spec/XALAction/@Type[not(. = $xal:xal-actions)])
};

(: ======================================================================
   Implements XAL (XML Aggregation Language) update protocol
   Subject - Object version for dual container element upate (e.g. to maintain references)
   Supports the Pivot attribute
   Throws an Oppdum error if some action is not implemented
   ====================================================================== 
:)
declare function xal:apply-updates( $subject as element(), $object as element()?, $spec as element() ) {
  if (every $fragment in $spec/XALAction satisfies $fragment/@Type = $xal:xal-pivot-actions) then (: sanity check :)
    for $fragment in $spec/XALAction
    let $pivot := if (exists($fragment/@Pivot)) then util:eval(string($fragment/@Pivot)) else $subject
    return
      if ($fragment/@Type eq 'replace') then
        for $cur in $fragment/*
        return local:apply-xal-replace($pivot, $cur)
      else if ($fragment/@Type eq 'insert') then
        for $cur in $fragment/*
        return local:apply-xal-insert($pivot, $cur)
      else if ($fragment/@Type eq 'timestamp') then
        for $cur in $fragment/*
        return local:apply-xal-timestamp($pivot, $cur, $fragment)
      else
        ()
  else
    oppidum:throw-error('XAL-UNKOWN-ACTION', $spec/XALAction/@Type[not(. = $xal:xal-pivot-actions)])
};

