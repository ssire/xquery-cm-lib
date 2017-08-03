xquery version "1.0";
(: --------------------------------------
   XQuery Content Management Library

   This is a sample Case Tracker Pilote file to build a person search
   functionality. You MOST probably will need to copy this file to your 
   project to customize it to fit your application data model.

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Shared database requests for persons search

   January 2015 - (c) Copyright 2015 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

module namespace search = "http://oppidoc.com/ns/xcm/search";

declare namespace httpclient = "http://exist-db.org/xquery/httpclient";

import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../../lib/globals.xqm";
import module namespace access = "http://oppidoc.com/ns/xcm/access" at "../../lib/access.xqm";
import module namespace user = "http://oppidoc.com/ns/xcm/user" at "../../lib/user.xqm";
import module namespace display = "http://oppidoc.com/ns/xcm/display" at "../../lib/display.xqm";
import module namespace misc = "http://oppidoc.com/ns/xcm/misc" at "../../lib/util.xqm";

(: ======================================================================
   Generates Person information fields to display in result table
   Includes an Update attribute flag if update is true()
   TODO: include Country fallback to first Case enterprise country for coach
   or to EEN Entity country for KAM/Coord ?
   ======================================================================
:)
declare function search:gen-person-sample ( $person as element(), $country as xs:string?, $role-ref as xs:string?, $lang as xs:string, $update as xs:boolean ) as element() {
  let $e := globals:doc('enterprises-uri')/Enterprises/Enterprise[Id = $person/EnterpriseRef/text()]
  return
    <Person>
      {(
        if ($update) then attribute  { 'Update' } { 'y' } else (),
        $person/(Id | Name | Contacts),
        if ($country) then
          <Country>{ $country }</Country>
        else if ($person/Country) then
          <Country>{ display:gen-name-for('Countries', $person/Country, $lang) }</Country>
        else if ($e/Address/Country) then (: defaults to enterprise's country :)
          <Country>{ display:gen-name-for('Countries', $e/Address/Country, $lang) }</Country>
        else
          (),
        if ($e) then
          <EnterpriseName>{$e/Name/text()}</EnterpriseName>
        else
         ()
        (: extra information to show EEN Entity in case coordinator :)
        (:if ($person/UserProfile/Roles/Role[FunctionRef/text() = $een-coordinator]) then
                  misc:gen_display_name($person/UserProfile/Roles/Role[FunctionRef/text() = $een-coordinator]/RegionalEntityRef, 'RegionalEntityName')
                else
                  ():)
      )}
    </Person>
};

(: ======================================================================
   Generates Person information fields to display in result table
   Includes an Update attribute flag if update is true()
   TODO: include Country fallback to first Case enterprise country for coach
   or to EEN Entity country for KAM/Coord ?
   ======================================================================
:)
declare function search:gen-person-sample ( $person as element(), $role-ref as xs:string?, $lang as xs:string, $update as xs:boolean ) as element() {
  let $e := globals:doc('enterprises-uri')/Enterprises/Enterprise[Id = $person/EnterpriseRef/text()]
  return
    <Person>
      {(
        if ($update) then attribute  { 'Update' } { 'y' } else (),
        $person/(Id | Name | Contacts),
        if ($person/Country) then
          <Country>{ display:gen-name-for('Countries', $person/Country, $lang) }</Country>
        else if ($e/Address/Country) then (: defaults to enterprise's country :)
          <Country>{ display:gen-name-for('Countries', $e/Address/Country, $lang) }</Country>
        else
          (),
        if ($e) then
          <EnterpriseName>{$e/Name/text()}</EnterpriseName>
        else
         ()
        (: extra information to show EEN Entity in case coordinator :)
        (:if ($person/UserProfile/Roles/Role[FunctionRef/text() = $een-coordinator]) then
                  misc:gen_display_name($person/UserProfile/Roles/Role[FunctionRef/text() = $een-coordinator]/RegionalEntityRef, 'RegionalEntityName')
                else
                  ():)
      )}
    </Person>
};

(: ======================================================================
   Returns community member(s) matching request
   FIXME: hard-coded function refs -> user:get-function-ref-for-role('xxx')
   ======================================================================
:)
declare function search:fetch-persons ( $request as element() ) as element()* {
  let $person := $request/Persons/PersonRef/text()
  let $country := $request//Country
  let $function := $request/Functions/FunctionRef/text()
  let $enterprise := $request/Enterprises/EnterpriseRef/text()
  let $region-role-ref := user:get-function-ref-for-role("region-manager")
  let $omni := access:check-entity-permissions('update', 'Person')
  let $uid := if ($omni) then () else user:get-current-person-id()
  return
    <Results>
      <Persons>
        {(
        if ($omni) then attribute { 'Update' } { 'y' } else (),
        if (empty($country)) then
          (: classical search :)
          for $p in globals:collection('persons-uri')//Person[empty($person) or Id/text() = $person]
          let $id := $p/Id/text()
          where (empty($function) or $p/UserProfile/Roles/Role/FunctionRef = $function)
            and (empty($enterprise) or $p/EnterpriseRef = $enterprise)
          order by $p/Name/LastName
          return
            search:gen-person-sample($p, $region-role-ref, 'en', not($omni) and $uid eq $p/Id/text())
            (: optimization for : not($omni) and access:check-person-update-at-least($uid, $person) :)
        else
        (: search by country direct mention :)
          let $with-country-refs := globals:collection('persons-uri')//Person[Country = $country]/Id[empty($person) or . = $person]
          (: extends to coaches having coached in one of the target country :)
          let $by-enterprise-refs := globals:doc('enterprises-uri')//Enterprise[Address/Country = $country]/Id
          let $by-coaching-refs := distinct-values(
            globals:collection('cases-uri')//Case[Information/ClientEnterprise/EnterpriseRef = $by-enterprise-refs]//ResponsibleCoachRef[not(. = $with-country-refs)]
            )
          (: extends to KAM having manage a case from the target country :)
          let $by-managing-refs := distinct-values(
            globals:collection('cases-uri')//Case/Management/AccountManagerRef[. = $by-enterprise-refs][not(. = $with-country-refs) and not(. = $by-coaching-refs)]
            )
          return (
            for $p in globals:collection('persons-uri')//Person[Id = $with-country-refs]
            where (empty($function) or $p/UserProfile/Roles/Role/FunctionRef = $function)
              and (empty($enterprise) or $p/EnterpriseRef = $enterprise)
            return
              search:gen-person-sample($p, (), $region-role-ref, 'en', not($omni) and $uid eq $p/Id),
            for $p in globals:collection('persons-uri')//Person[Id = $by-coaching-refs]
            where (empty($person) or $p/Id = $person)
              and (empty($function) or $p/UserProfile/Roles/Role/FunctionRef = $function)
              and (empty($enterprise) or $p/EnterpriseRef = $enterprise)
            return
              search:gen-person-sample($p, 'C', $region-role-ref, 'en', not($omni) and $uid eq $p/Id),
            for $p in globals:collection('persons-uri')//Person[Id = $by-managing-refs]
            where (empty($person) or $p/Id = $person)
              and (empty($function) or $p/UserProfile/Roles/Role/FunctionRef = $function)
              and (empty($enterprise) or $p/EnterpriseRef = $enterprise)
            return
              search:gen-person-sample($p, 'E', $region-role-ref, 'en', not($omni) and $uid eq $p/Id)
            )
        )}
      </Persons>
    </Results>
};

