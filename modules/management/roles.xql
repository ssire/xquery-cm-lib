xquery version "1.0";
(: --------------------------------------
   Case tracker pilote

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   User account management

   March 2014 - (c) Copyright 2014 Oppidoc SARL. All Rights Reserved. 
   ------------------------------------------------------------------ :)

import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../../lib/globals.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

(: ======================================================================
   Returns the list of users grouped by role 
   ======================================================================
:)
declare function local:gen-roles-for-viewing() as element()* {
  <Roles>
  {
  for $f in globals:collection('global-info-uri')//Description[@Role = 'normative']/Selector[@Name eq 'Functions']/Option
  return
    <Role Name="{string($f/Name)}">
    {
    string-join(
      for $p in globals:doc('persons-uri')//Person/UserProfile/Roles/Role/FunctionRef[. eq $f/Id]
      let $n := $p/ancestor::Person/Name
      return concat($n/FirstName, ' ', $n/LastName),
      ', '
    )
    }
    </Role>
  }
  </Roles>
};

local:gen-roles-for-viewing()
