xquery version "1.0";
(: --------------------------------------
   Case tracker pilote

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Form fields generation for user management module

   March 2014 - (c) Copyright 2014 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)
declare default element namespace "http://www.w3.org/1999/xhtml";

import module namespace form = "http://oppidoc.com/ns/xcm/form" at "../../lib/form.xqm";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";

declare namespace xt = "http://ns.inria.org/xtiger";
declare namespace site = "http://oppidoc.com/oppidum/site";

declare option exist:serialize "method=xml media-type=text/xml";

let $cmd := request:get-attribute('oppidum.command')
let $lang := string($cmd/@lang)
let $target := oppidum:get-resource(oppidum:get-command())/@name
let $goal := request:get-parameter('goal', 'read')
return
  if ($target = ('profile', 'remote')) then
    <site:view>
      <site:field Key="function">
        { form:gen-selector-for('Functions', $lang, ";multiple=no;typeahead=no") }
      </site:field>
      <site:field Key="services">
        { form:gen-selector-for('Services', $lang, ";multiple=yes;typeahead=no;xvalue=ServiceRef") }
      </site:field>
    </site:view>
  else (: only constant fields  :)
    <site:view/>
