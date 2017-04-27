xquery version "1.0";
(: --------------------------------------
   XQuery Content Management Library

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Implementation of the XAL (XML Aggregation Language) language (see templates.xml)

   April 2017 - (c) Copyright 2017 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

module namespace xal = "http://oppidoc.com/ns/xcm/xal";

(: ======================================================================
   Single XAL replace action implementation
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

(: =======================================================================
   Implements XAL (XML Aggregation Language) update protocol
   FIXME: currently only XALAction with 'replace' @Type
   =======================================================================
:)
declare function xal:apply-updates( $parent as element(), $spec as element() ) {
  for $fragment in $spec/XALAction[@Type eq 'replace']
  return
    for $cur in $fragment/*
    return local:apply-xal-replace($parent, $cur)
};

(: =======================================================================
   Implements XAL (XML Aggregation Language) update protocol
   FIXME: currently only XALAction with 'replace' @Type
   =======================================================================
:)
declare function xal:apply-updates( $parent as element(), $spec as element() ) {
  for $fragment in $spec/XALAction[@Type eq 'replace']
  return
    for $cur in $fragment/*
    let $legacy := $parent/*[local-name(.) eq local-name($cur)]
    return
      if (exists($legacy)) then
        update replace $legacy with $cur
      else
        update insert $cur into $parent
};

(: ======================================================================
   Version with pivot
   ====================================================================== 
:)
declare function xal:apply-updates( $subject as element(), $object as element()?, $spec as element() ) {
  for $fragment in $spec/XALAction[@Type eq 'replace']
  let $pivot := string($fragment/@Pivot)
  return
    for $cur in $fragment/*
    return
      if ($pivot) then
        local:apply-xal-replace(util:eval($pivot), $cur)
      else
        local:apply-xal-replace($subject, $cur)
};

