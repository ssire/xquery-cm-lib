xquery version "1.0";
(: --------------------------------------
   XQuery Content Management Library

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Generates controls for insertion into shared workflow templates

   November 2014 - (c) Copyright 2014 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

declare default element namespace "http://www.w3.org/1999/xhtml";

import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace form = "http://oppidoc.com/ns/xcm/form" at "../../lib/form.xqm";
import module namespace display = "http://oppidoc.com/ns/xcm/display" at "../../lib/display.xqm";
import module namespace misc = "http://oppidoc.com/ns/xcm/misc" at "../../lib/util.xqm";
import module namespace person = "http://oppidoc.com/ns/xcm/person" at "../persons/person.xqm";

declare namespace xt = "http://ns.inria.org/xtiger";
declare namespace site = "http://oppidoc.com/oppidum/site";

declare option exist:serialize "method=xml media-type=text/xml";

let $cmd := request:get-attribute('oppidum.command')
let $lang := string($cmd/@lang)
let $goal := request:get-parameter('goal', 'read')
let $template := string(oppidum:get-resource($cmd)/@name)
return
  if ($goal = 'read') then
    <site:view/>
  else
    if ($template = ('mail')) then
      <site:view>
        <site:field Key ="date">
          <xt:use types="constant" param="class=uneditable-input span">
            { display:gen-display-date(string(current-date()),$lang) }
          </xt:use>
        </site:field>
        <site:field Key="sender">
          <xt:use types="constant" param="class=uneditable-input span">
            { misc:gen-current-person-name() }
          </xt:use>
        </site:field>
        <site:field Key="addressees">
          {
          let $field := person:gen-person-selector($lang, ";multiple=yes;xvalue=AddresseeRef;typeahead=yes")
          return
            <xt:use types="choice" values="-1 {$field/@values}" i18n="nobody::only\ for\ archiving {$field/@i18n}" param="{$field/@param}"/>
          }
        </site:field>
      </site:view>
  else
    <site:view/>
