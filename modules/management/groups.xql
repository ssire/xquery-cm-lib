xquery version "1.0";
(: --------------------------------------
   Case tracker pilote

   Creator: Stéphane Sire <sire@oppidoc.fr>

   Utility script to batch create (or update) users 

   To be executed directly from-within eXist-BB jav admin client
   
   FIXME: move this script to modules/users/groups.xql ?
   
   NOTE: I notice that if this script is saved without group access to "r"
   then when under Tomcat it triggers Basic Authentication dialog !

   February 2014 - (c) Copyright 2014 Oppidoc SARL. All Rights Reserved.
   -------------------------------------- :)

import module namespace sm = "http://exist-db.org/xquery/securitymanager";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../../lib/globals.xqm";
import module namespace account = "http://oppidoc.com/ns/xcm/account" at "../users/account.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

(: ======================================================================
   Compares users with Username's groups as per UserProfile 
   with eXist-DB groups
   ======================================================================
:)
declare function local:find-users-that-need-repair() {
  for $p in globals:doc('persons-uri')/Persons/Person
  let $login := $p//Username/text()
  where $login
  order by lower-case($login)
  return
    let $has := if (sm:user-exists(string($login))) then sm:get-user-groups(string($login)) else '-1' 
    let $should := account:gen-groups-for-user($p)
    return
      if ($has = '-1') then
        <tr><td>{$login}</td><td>N/A</td><td>---</td><td>{$should}</td></tr>
      else if ( (every $x in $has satisfies $x = $should) and (every $y in $should satisfies $y = $has) ) then
        <tr><td>{$login}</td><td>OK</td><td>{$has}</td><td>{$should}</td></tr>
      else
        <tr><td>{$login}</td><td>MISS</td><td>{$has}</td><td>{$should}</td></tr>
};

(: ======================================================================
   Fixes users groups to make eXist-DB groups in synch with UserProfile 
   groups as per Roles defined for each user
   ======================================================================
:)
declare function local:repair-users() {
  for $p in globals:doc('persons-uri')/Persons/Person
  let $login := $p//Username/text()
  where $login
  order by lower-case($login)
  return
    let $has := if (sm:user-exists(string($login))) then sm:get-user-groups(string($login)) else '-1' 
    let $should := account:gen-groups-for-user($p)
    return
      if ($has = '-1') then
        <tr><td>{$login}</td><td>N/A</td><td>---</td><td>{$should}</td></tr>
      else if ( (every $x in $has satisfies $x = $should) and (every $y in $should satisfies $y = $has) ) then
        <tr><td>{$login}</td><td>OK</td><td>{$has}</td><td>{$should}</td></tr>
      else (
        account:set-user-groups($login, $should),
        <tr style="color:green"><td>{$login}</td><td>FIXED</td><td><del>{$has}</del> / {$should}</td><td>{$should}</td></tr>
        )
};

let $repair := request:get-parameter('nrepair', ())
return
  <div id="c-groups-results">
    {
    if ($repair = '1') then
      <h1>Groups repair</h1>
    else (
      <h1>Groups diagnosis</h1>,
      if (oppidum:get-current-user() = 'admin') then
        <p>Click to <a href="#" onclick="javascript:$('#c-groups-results').load('management/groups?nrepair=1')">Repair</a></p>
      else
        <p>Si certains identifiants ont le statut MISS demandez à un administrateur de la base de donnée de réparer les groupes</p>
      )
    }
    {
    if (($repair = '1') and (oppidum:get-current-user() ne 'admin')) then
      <p>Seul un administrateur de la base de donnée peut réparer les groupes, demandez le lui !</p>
    else
      <table class="table table-bordered">
      <tr>
        <th>Identifiant</th>
        <th>Statut</th>
        <th>eXist-DB</th>
        <th>UserProfile</th>
      </tr>
      { 
      if ($repair = '1') then
        local:repair-users() 
      else
        local:find-users-that-need-repair() 
      }
      </table>
    }
  </div>
