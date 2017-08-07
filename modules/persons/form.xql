xquery version "1.0";
(: --------------------------------------
   Case tracker pilote

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Generates extension points for Person search and Person formulars

   FIXME:
   - replace form:gen-coach-selector by form:gen-person-selector when goal is to search ?
   - generate (and localize) sex, civility and function fields from DB content ?

   September 2013 - (c) Copyright 2013 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

declare default element namespace "http://www.w3.org/1999/xhtml";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace form = "http://oppidoc.com/ns/xcm/form" at "../../lib/form.xqm";
import module namespace person = "http://oppidoc.com/ns/xcm/person" at "../persons/person.xqm";
import module namespace enterprise = "http://oppidoc.com/ns/xcm/enterprise" at "../enterprises/enterprise.xqm";

declare namespace xt = "http://ns.inria.org/xtiger";
declare namespace site = "http://oppidoc.com/oppidum/site";

declare option exist:serialize "method=xml media-type=text/xml";

let $cmd := request:get-attribute('oppidum.command')
let $lang := string($cmd/@lang)
let $target := oppidum:get-resource(oppidum:get-command())/@name
let $goal := request:get-parameter('goal', 'read')
return
  if ($target = 'persons') then (: Person search form :)
      <site:view>
        <site:field Key="persons">
        { person:gen-person-selector($lang, ";multiple=yes;typeahead=yes;xvalue=PersonKey") }
      </site:field>
      <site:field Key="countries">
        { form:gen-selector-for('Countries', $lang, ";multiple=yes;xvalue=Country;typeahead=yes") }
      </site:field>
      <site:field Key="enterprises">
        { enterprise:gen-enterprise-selector($lang, ";multiple=yes;xvalue=EnterpriseKey;typeahead=yes") }
      </site:field>
      <site:field Key="functions">
        { form:gen-selector-for('Functions', $lang, ";multiple=yes;typeahead=no;xvalue=FunctionRef") }
      </site:field>
      <site:field Key="services">
        { form:gen-selector-for('Services', $lang, ";multiple=yes;typeahead=no;xvalue=ServiceRef") }
      </site:field>
      </site:view>
  else if ($goal = ('update','create')) then
    <site:view>
      {
      if ($goal = 'create') then
        <site:field Key="lastname">
          { form:filter-select2-tags(person:gen-person-enterprise-selector($lang, ";select2_tags=yes;typeahead=yes")) }
        </site:field>
      else
        <site:field Key="lastname" filter="no">
          <xt:use types="input" param="filter=optional event;class=span a-control;required=true;" label="LastName"></xt:use>
        </site:field>
      }
      <site:field Key="sex">
        <xt:use types="choice"
        values="M F"
        i18n="M F"
        param="class=span12 a-control"
        >M</xt:use>
      </site:field>
      <site:field Key="countries">
        { form:gen-selector-for('Countries', $lang, " optional;multiple=no;typeahead=yes") }
      </site:field>
      <site:field Key="enterprise">
        { enterprise:gen-enterprise-selector($lang, ' optional;multiple=no;typeahead=yes') }
      </site:field>
    </site:view>
  else (: 'read' - only constant fields  :)
    <site:view/>
