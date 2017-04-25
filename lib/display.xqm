xquery version "1.0";
(: --------------------------------------
   XQuery Content Management Library

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Functions to generate strings for display out of database content
   All generated strings are localized to the language passed as parameter

   NOTE:
   - as (most of) these functions return strings to be inserted in text readonly
     input fields to show static views, we prefer to localize them directly
     instead of generating localization keys for post-render localization,
     generating keys would most probably imply to return an @i18n attribute
     and thus to be careful about invocation context

   OPTIMIZATION:
   - use a cache mechanism when possible if too slow

   November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

module namespace display = "http://oppidoc.com/ns/xcm/display";

declare namespace site = "http://oppidoc.com/oppidum/site";

import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../lib/globals.xqm";

(: ======================================================================
   Returns a hard coded string in case of an unkown reference
   FIXME:
   - read the string from the application thesaurus when available
   ======================================================================
:)
declare function display:noref( $ref as xs:string, $lang as xs:string ) as xs:string {
  concat("unknown reference (", $ref, ")")
};

(: ======================================================================
   Formats a date for screen display
   ======================================================================
:)
declare function display:gen-display-date( $date as xs:string?, $lang as xs:string ) as xs:string {
  if ($date) then
    concat(substring($date,9,2), '/', substring($date,6,2), '/', substring($date,1,4))
  else
    ('')
};

(: ======================================================================
   Converts a reference to an option in a list into the option label
   Version with encoded value passed as string reference
   ======================================================================
:)
declare function display:gen-name-for-sref ( $name as xs:string, $ref as xs:string?, $lang as xs:string ) as xs:string+ {
  if ($ref) then 
    let $defs := globals:collection('global-info-uri')//Description[@Lang = $lang]//Selector[@Name eq $name]
    let $label := if (starts-with($defs/@Label, 'V+')) then substring-after($defs/@Label, 'V+') else string($defs/@Label)
    let $option := $defs//Option[*[local-name(.) eq string($defs/@Value)]/text() eq $ref]/*[local-name(.) eq $label]
    return
      if ($option) then
        if (contains($option, '::')) then (: satellite :)
          concat(substring-before($option, '::'), ' (', substring-after($option, '::'), ')')
        else
          $option
          (: FIXME: concatenate with $ref when 'V+' as in forms.xqm
            if ($concat) then concat($v, ' ', $p/*[local-name(.) eq $label]) else $p/*[local-name(.) eq $label] :)
      else
        display:noref($ref, $lang)
  else
    ''
};

declare function local:gen-list-for ( $name as xs:string, $items as element()*, $lang as xs:string ) as xs:string {
  string-join(
    for $r in $items
    return display:gen-name-for-sref($name, $r/text(), $lang),
    ', '
    )
};

(: ======================================================================
   Converts a list of references to a Selector to to a list of labels
   Note space after comma so that browsers cut long lists correctly
   ======================================================================
:)
declare function display:gen-name-for ( $name as xs:string, $refs as element()*, $lang as xs:string ) as xs:string {
  if (count($refs) > 1) then
    local:gen-list-for($name, $refs, $lang)
  else
    display:gen-name-for-sref($name, $refs/text(), $lang)
};

(: ======================================================================
   Generates a person name (First name, Surname) from a reference to a person
   ======================================================================
:)
declare function display:gen-person-name( $ref as xs:string?, $lang as xs:string ) {
  if ($ref) then
    let $p := globals:doc('persons-uri')/Persons/Person[Id = $ref]
    return
      if ($p) then
        concat($p/Name/FirstName, ' ', $p/Name/LastName)
      else if ($ref eq 'import') then
        "case tracker importer"
      else if ($ref eq 'batch') then
        "case tracker batch"
      else
        display:noref($ref, $lang)
  else
    ""
};

(: ======================================================================
   Generates a person name (Surname, First name) from a reference to a person
   ======================================================================
:)
declare function display:gen-name-person( $ref as xs:string?, $lang as xs:string ) {
  if ($ref) then
    let $p := globals:doc('persons-uri')/Persons/Person[Id = $ref]
    return
      if ($p) then
        concat($p/Name/LastName, ' ', $p/Name/FirstName)
      else if ($ref eq 'import') then
        "case tracker importer"
      else if ($ref eq 'batch') then
        "case tracker batch"
      else
        display:noref($ref, $lang)
  else
    ""
};

(: ======================================================================
   Generates a person email from a reference to a person
   or a localized unknown reference message
   ======================================================================
:)
declare function display:gen-person-email( $ref as xs:string?, $lang as xs:string ) {
  if ($ref) then
    let $p := globals:doc('persons-uri')/Persons/Person[Id = $ref]
    return
      if ($p) then
        $p/Contacts/Email/text()
      else
        display:noref($ref, $lang)
  else
    ""
};

(: ======================================================================
   Converts a Roles model into a comma separated list of role names
   TODO: localize
   ======================================================================
:)
declare function display:gen-roles-for ( $roles as element()?, $lang as xs:string ) as xs:string? {
  if (exists($roles/Role)) then
    string-join(
      for $fref in $roles/Role/FunctionRef
      return
        globals:collection('global-info-uri')//Description[@Lang = $lang]/Selector[@Name eq 'Functions']/Option[Id eq $fref]/Brief,
      ', '
      )
  else
    '...'
};

