xquery version "1.0";
(: --------------------------------------
   Case tracker pilote

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Person entity utilities

   April 2017 - (c) Copyright 2017 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

module namespace person = "http://oppidoc.com/ns/xcm/person";

import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../../lib/globals.xqm";
import module namespace form = "http://oppidoc.com/ns/xcm/form" at "../../lib/form.xqm";
import module namespace user = "http://oppidoc.com/ns/xcm/user" at "../../lib/user.xqm";

declare namespace xt = "http://ns.inria.org/xtiger";

(: ======================================================================
   Generates XTiger XML 'choice' element for selecting a person
   We do a single-pass algorithm to be sure we get same ordering between Names and Ids
   FIXME: handle case with no Person in database (?)
   ======================================================================
:)
declare function person:gen-person-selector ( $lang as xs:string, $params as xs:string ) as element() {
  let $pairs :=
      for $p in globals:collection('persons-uri')//Person
      let $info := $p/Information
      let $fn := $info/Name/FirstName
      let $ln := $info/Name/LastName
      where ($info/Name/LastName ne '')
      order by $ln ascending
      return
         <Name id="{$p/Id/text()}">{concat(replace($ln,' ','\\ '), '\ ', replace($fn,' ','\\ '))}</Name>
  return
    let $ids := string-join(for $n in $pairs return string($n/@id), ' ') (: FLWOR to defeat document ordering :)
    let $names := string-join(for $n in $pairs return $n/text(), ' ') (: idem :)
    return
      <xt:use types="choice" values="{$ids}" i18n="{$names}" param="{form:setup-select2($params)}"/>
};

(: ======================================================================
   Same as function form:gen-person-selector with a restriction to a given Role
   ======================================================================
:)
declare function person:gen-person-with-role-selector ( $roles as xs:string+, $lang as xs:string, $params as xs:string, $class as xs:string? ) as element() {
  let $roles-ref := user:get-function-ref-for-role($roles)
  let $pairs :=
      for $p in globals:collection('persons-uri')//Person[UserProfile//Role[FunctionRef = $roles-ref]]
      let $name := $p/Information/Name
      let $fn := $name/FirstName
      let $ln := $name/LastName
      where ($name/LastName/text() ne '')
      order by $ln ascending
      return
         <Name id="{$p/Id/text()}">{concat(replace($ln,' ','\\ '), '\ ', replace($fn,' ','\\ '))}</Name>
  return
    let $ids := string-join(for $n in $pairs return string($n/@id), ' ') (: FLWOR to defeat document ordering :)
    let $names := string-join(for $n in $pairs return $n/text(), ' ') (: idem :)
    return
      if ($ids) then
        <xt:use types="choice" values="{$ids}" i18n="{$names}" param="{form:setup-select2($params)}"/>
      else
        <xt:use types="constant" param="noxml=true;class=uneditable-input {$class}">Not available</xt:use>
};

(: ======================================================================
  Same as form:gen-person-selector but with person's enterprise as a satellite
  It doubles request execution times
   ======================================================================
:)
declare function person:gen-person-enterprise-selector ( $lang as xs:string, $params as xs:string ) as element() {
  let $pairs :=
      for $p in globals:collection('persons-uri')//Person
      let $info := $p/Information
      let $fn := $info/Name/FirstName
      let $ln := $info/Name/LastName
      let $pe := $info/EnterpriseKey/text()
      order by $ln ascending
      return
        let $en := if ($pe) then globals:doc('enterprises-uri')//Enterprise[Id = $pe]/Name/text() else ()
        return
          <Name id="{$p/Id/text()}">{concat(replace($ln,' ','\\ '), '\ ', replace($fn,' ','\\ '))}{if ($en) then concat('::', replace($en,' ','\\ ')) else ()}</Name>
  return
    let $ids := string-join(for $n in $pairs return string($n/@id), ' ') (: FLWOR to defeat document ordering :)
    let $names := string-join(for $n in $pairs return $n/text(), ' ') (: idem :)
    return
      <xt:use types="choice" values="{$ids}" i18n="{$names}" param="select2_complement=town;{form:setup-select2($params)}"/>
};
