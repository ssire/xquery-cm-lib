xquery version "1.0";
(: --------------------------------------
   XQuery Content Management Library

   Shared database requests for persons search

   This is a sample file for Case Tracker Pilote

   You MOST probably will need to copy this file to your 
   project to customize it to fit your application data model

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   August 2017 - (c) Copyright 2017 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

module namespace search = "http://oppidoc.com/ns/xcm/search";

import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../../lib/globals.xqm";
import module namespace access = "http://oppidoc.com/ns/xcm/access" at "../../lib/access.xqm";
import module namespace user = "http://oppidoc.com/ns/xcm/user" at "../../lib/user.xqm";
import module namespace display = "http://oppidoc.com/ns/xcm/display" at "../../lib/display.xqm";
import module namespace misc = "http://oppidoc.com/ns/xcm/misc" at "../../lib/util.xqm";

(: ======================================================================
   Generates Person information fields to display in result table
   The $opt-country is a conventional string that replaces the country 
   to tell it has been deduced from other data
   Includes an Update attribute flag if update is true()
   ======================================================================
:)
declare function search:gen-person-sample ( $person as element(), $opt-country as xs:string?, $update as xs:boolean, $lang as xs:string ) as element() {
  let $e := globals:doc('enterprises-uri')//Enterprise[Id = $person/Information/EnterpriseKey]
  let $info := $person/Information
  return
    <Person>
      {
      if ($update) then attribute  { 'Update' } { 'y' } else (),
      $person/Id,
      $info/(Name | Contacts),
      if ($opt-country) then
        <Country>{ $opt-country }</Country>
      else if ($info/Country) then
        <Country>{ display:gen-name-for('Countries', $info/Country, $lang) }</Country>
      else if ($e/Information/Address/Country) then (: fallbacks to enterprise's country :)
        <Country>{ display:gen-name-for('Countries', $e/Information/Address/Country, $lang) }</Country>
      else
        (),
      if ($e) then
        <EnterpriseName>{ $e/Information/Name/text() }</EnterpriseName>
      else
       ()
      }
    </Person>
};

(: ======================================================================
   Generates Person information fields to display in result table
   Includes an Update attribute flag if update is true()
   ======================================================================
:)
declare function search:gen-person-sample ( $person as element(), $update as xs:boolean, $lang as xs:string ) as element() {
  search:gen-person-sample($person, (), $update, $lang)
};

(: ======================================================================
   Returns community member(s) matching request
   ======================================================================
:)
declare function search:fetch-persons ( $request as element() ) as element()* {
  let $person := $request/Persons/PersonKey/text()
  let $country := $request//Country
  let $function := $request/Functions/FunctionRef/text()
  let $enterprise := $request/Enterprises/EnterpriseKey/text()
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
            and (empty($enterprise) or $p/Information/EnterpriseKey = $enterprise)
          order by $p/Information/Name/LastName
          return
            search:gen-person-sample($p, (), not($omni) and $uid eq $p/Id, 'en')
            (: optimization for : not($omni) and access:check-person-update-at-least($uid, $person) :)
        else
        (: search by country direct mention :)
          let $with-country-refs := globals:collection('persons-uri')//Person[Country = $country]/Id[empty($person) or . = $person]
          (: extends to coaches having coached in one of the target country :)
          let $by-enterprise-refs := globals:doc('enterprises-uri')//Enterprise[Address/Country = $country]/Id
          let $by-coaching-refs := distinct-values(
            globals:collection('cases-uri')//Case[Information/ClientEnterprise/EnterpriseKey = $by-enterprise-refs]//ResponsibleCoachKey[not(. = $with-country-refs)]
            )
          (: extends to KAM having manage a case from the target country :)
          let $by-managing-refs := distinct-values(
            globals:collection('cases-uri')//Case/Management/AccountManagerKey[. = $by-enterprise-refs][not(. = $with-country-refs) and not(. = $by-coaching-refs)]
            )
          return (
            for $p in globals:collection('persons-uri')//Person[Id = $with-country-refs]
            where (empty($function) or $p/UserProfile/Roles/Role/FunctionRef = $function)
              and (empty($enterprise) or $p/Information/EnterpriseKey = $enterprise)
            return
              search:gen-person-sample($p, (), not($omni) and $uid eq $p/Id, 'en'),
            for $p in globals:collection('persons-uri')//Person[Id = $by-coaching-refs]
            where (empty($person) or $p/Id = $person)
              and (empty($function) or $p/UserProfile/Roles/Role/FunctionRef = $function)
              and (empty($enterprise) or $p/Information/EnterpriseKey = $enterprise)
            return
              search:gen-person-sample($p, 'C', not($omni) and $uid eq $p/Id, 'en'),
            for $p in globals:collection('persons-uri')//Person[Id = $by-managing-refs]
            where (empty($person) or $p/Id = $person)
              and (empty($function) or $p/UserProfile/Roles/Role/FunctionRef = $function)
              and (empty($enterprise) or $p/Information/EnterpriseKey = $enterprise)
            return
              search:gen-person-sample($p, 'E', not($omni) and $uid eq $p/Id, 'en')
            )
        )}
      </Persons>
    </Results>
};

