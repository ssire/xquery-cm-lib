xquery version "1.0";
(: --------------------------------------
   Case tracker pilote

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Enterprise entity utilities

   November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

module namespace enterprise = "http://oppidoc.com/ns/xcm/enterprise";

import module namespace request="http://exist-db.org/xquery/request";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../../lib/globals.xqm";
import module namespace form = "http://oppidoc.com/ns/xcm/form" at "../../lib/form.xqm";
import module namespace display = "http://oppidoc.com/ns/xcm/display" at "../../lib/display.xqm";
import module namespace ajax = "http://oppidoc.com/ns/xcm/ajax" at "../../lib/ajax.xqm";
import module namespace cache = "http://oppidoc.com/ns/xcm/cache" at "../../lib/cache.xqm";

declare namespace xt = "http://ns.inria.org/xtiger";

(: ======================================================================
   Normalizes a string to compare it with another one
   TODO: handle accentuated characters (canonical form ?)
   ======================================================================
:)
declare function local:normalize( $str as xs:string? ) as xs:string {
  upper-case(normalize-space($str))
};

(: ======================================================================
   Generates an enterprise name from a reference to an enterprise
   ======================================================================
:)
declare function enterprise:gen-enterprise-name( $ref as xs:string?, $lang as xs:string ) {
  if ($ref) then
    let $p := globals:doc('enterprises-uri')/Enterprises/Enterprise[Id = $ref]
    return
      if ($p) then
        $p/Name/text()
      else
        display:noref($ref, $lang)
  else
    ""
};
(: ======================================================================
   Generates an element with a given tag holding the display name of the enterprise
   passed as a parameter and its reference as content
   ======================================================================
:)
declare function enterprise:unreference-enterprise( $ref as element()?, $tag as xs:string, $lang as xs:string ) as element() {
  let $sref := $ref/text()
  return
    element { $tag }
      {(
      attribute { '_Display' } { enterprise:gen-enterprise-name($sref, $lang) },
      $sref
      )}
};

(: ======================================================================
   Generates XTiger XML 'choice' element for selecting an enterprise
   We do a single-pass algorithm to be sure we get same ordering between Names and Ids
   ======================================================================
:)
declare function enterprise:gen-enterprise-selector ( $lang as xs:string, $params as xs:string ) as element() {
  let $inCache := cache:lookup('enterprise', $lang)
  return
    if ($inCache) then
      <xt:use hit="1" types="choice" values="{$inCache/Values}" i18n="{$inCache/I18n}" param="select2_complement=town;select2_minimumInputLength=2;{form:setup-select2($params)}"/>
    else
      let $pairs :=
          for $p in globals:doc('enterprises-uri')/Enterprises/Enterprise[not(@EnterpriseId)]
          let $n := $p/Name
          order by $n ascending
          return
             <Name id="{$p/Id/text()}">{replace($n,' ','\\ ')}{if ($p/Address/Town/text()) then concat('::', replace($p/Address/Town,' ','\\ ')) else ()}</Name>
      return
        let $ids := string-join(for $n in $pairs return string($n/@id), ' ') (: FLWOR to defeat document ordering :)
        let $names := string-join(for $n in $pairs return $n/text(), ' ') (: idem :)
        return (
          cache:update('enterprise',$lang, $ids, $names),
          <xt:use types="choice" values="{$ids}" i18n="{$names}" param="select2_complement=town;select2_minimumInputLength=2;{form:setup-select2($params)}"/>
          )
};

(: ======================================================================
   Generates XTiger XML 'choice' element for selecting an enterprise town
   We do a single-pass algorithm to be sure we get same ordering between Names and Ids
   ======================================================================
:)
declare function enterprise:gen-town-selector ( $lang as xs:string, $params as xs:string ) as element() {
  let $inCache := cache:lookup('town', $lang)
  return
    if ($inCache) then
      <xt:use hit="1" types="choice" values="{$inCache/Values}" param="{form:setup-select2($params)}"/>
    else
      let $towns :=
        for $t in distinct-values ((globals:doc('enterprises-uri')//Enterprise[not(@EnterpriseId)]/Address/Town/text()))
        order by $t ascending
        return
          replace($t,' ','\\ ')
      return
        let $ids := string-join($towns, ' ')
        return (
          cache:update('town',$lang, $ids, ()),
          <xt:use types="choice" values="{$ids}" param="{form:setup-select2($params)}"/>
          )
};

(: ======================================================================
   Checks submitted enterprise data is valid and check Name fields 
   are unique or correspond to the submitted enterprise in case of update ($curNo defined).
   Returns a list of error messages or the emtpy sequence if no errors.
   TODO: improve error generation for internationalization
   ======================================================================
:)
declare function enterprise:validate-enterprise-submission( $data as element(), $curNo as xs:string? ) as element()* {
  let $key1 := local:normalize($data/Name/text())
  let $cname := globals:doc('enterprises-uri')/Enterprises/Enterprise[local:normalize(Name) = $key1]
  return (
      if ($curNo and empty(globals:doc('enterprises-uri')/Enterprises/Enterprise[Id = $curNo])) then
        ajax:throw-error('UNKNOWN-ENTERPRISE', $curNo)
      else (),
      if ($cname) then 
        if (not($curNo) or ($cname/Id != $curNo)) then
          ajax:throw-error('ENTERPRISE-NAME-CONFLICT', $data/Name/text())
        else ()
      else ()
      )
};

(: ======================================================================
   Serializes new element if it exists 
   ======================================================================
:)
declare function local:persists_annotation( $current as element()?, $new as element()? ) as element()? {
  if ($new) then
    if ($current/@_Source) then (: persists importer _Source annotation :)
      element { local-name($new) } {(
        $current/@_Source,
        $new/text()
      )}
    else
      $new
  else
    ()
};

(: ======================================================================
   Reconstructs an Enterprise record from current Enterprise data and from new submitted
   Enterprise data. Current Enterprise may be the empty sequence in case of creation.
   ======================================================================
:)
declare function enterprise:gen-enterprise-for-writing( $current as element()?, $new as element(), $index as xs:integer? ) {
  <Enterprise>
    {(
    if ($current) then 
      (
      $current/@EnterpriseId,
      $current/Id
      )
    else 
      <Id>{$index}</Id>,
    $new/Name,
    $new/ShortName,
    local:persists_annotation($current/CreationYear, $new/CreationYear),
    local:persists_annotation($current/SizeRef, $new/SizeRef),
    $new/DomainActivityRef,
    $new/WebSite,
    $new/MainActivities,
    $new/TargetedMarkets,
    $new/Address
    )}
  </Enterprise>
};

(: ======================================================================
   Updates an enterprise record into database if the submitted data is different
   Invalidates cache in case enterprise name 
   Returns true() if data was updated, false() otherwise (no need to update)
   ======================================================================
:)
declare function enterprise:update-enterprise( $ref as xs:string, $data as element(), $lang as xs:string ) as xs:boolean {
  let $current := globals:doc('enterprises-uri')/Enterprises/Enterprise[Id = $ref]
  let $new := enterprise:gen-enterprise-for-writing($current, $data, ())
  let $dirty-name := $current/Name/text() ne $new/Name/text()
  let $dirty-town := $current/Address/Town/text() ne $new/Address/Town/text()
  return
    if (deep-equal($current, $new)) then
      false()
    else
      (
      update replace $current with $new,
      if ($dirty-name) then cache:invalidate('enterprise', $lang) else (),
      if ($dirty-town) then cache:invalidate('town', $lang) else (),
      true()
      )[last()]
};
