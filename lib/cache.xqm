xquery version "1.0";
(: --------------------------------------
   XQuery Content Management Library

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Cache API

   TODO:
   - rewrite to save each category in a 'category-en.xml' file
   - plug onto form:gen-selector-for
   - make a control panel management/cache.xql

   November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

module namespace cache = "http://oppidoc.com/ns/xcm/cache";

import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../lib/globals.xqm";

(: ======================================================================
   Searches in cache an Entry for the field identified with $name and $lang and returns it
   Returns the empty sequence if not found
   ======================================================================
:)
declare function cache:lookup( $name as xs:string, $lang as xs:string ) as element()*
{
  globals:doc('cache-uri')//Entry[@Id eq $name][@lang eq $lang][not(@Dirty)]
};

(: ======================================================================
   Updates the corresponding cache entry identified with $name and $lang
   ======================================================================
:)
declare function cache:update( $name as xs:string, $lang as xs:string, $values as xs:string,  $i18n as xs:string?) {
  if (globals:doc-available('cache-uri')) then
    let $found := globals:doc('cache-uri')//Entry[@Id eq $name][@lang eq $lang]
    let $fresh :=
      <Entry Id="{$name}" lang="{$lang}">
        <Values>{ $values }</Values>
        { if ($i18n) then <I18n>{ $i18n }</I18n> else () }
      </Entry>
    return
      if ($found) then
        update replace $found with $fresh
      else
        update insert $fresh into globals:doc('cache-uri')/Cache
  else (: cache not activated :)
    ()
};

(: ======================================================================
   Sets Dirty flag on corresponding cache entries
   ======================================================================
:)
declare function cache:invalidate( $name as xs:string, $lang as xs:string ) {
  if (globals:doc-available('cache-uri')) then
    let $found := globals:doc('cache-uri')//Entry[@Id eq $name][@lang eq $lang]
    return
      if ($found) then
        if ($found/@Dirty) then
          update value $found/@Dirty with '1'
        else
          update insert attribute { 'Dirty' } { '1' } into $found
      else
        ()
  else
    () (: cache not activated :)
};
