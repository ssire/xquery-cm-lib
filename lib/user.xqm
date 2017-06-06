xquery version "1.0";
(:~ 
 : XQuery Content Management Library
 :
 : This module provides the functions that give access to the user profile.
 :
 : November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
 :
 : @author Stéphane Sire
 :)
module namespace user = "http://oppidoc.com/ns/xcm/user";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "globals.xqm";

(:~
 : Gets the identifier of the current user or the empty sequence 
 : if the current user is not associated with a person in the databse.
 :)
declare function user:get-current-person-id () as xs:string? {
  user:get-current-person-id (oppidum:get-current-user())
};

(:~
 : Variant of <i>template:get-current-person-id</i> when the current user is known
 :)
declare function user:get-current-person-id ( $user as xs:string ) as xs:string? {
  let $realm := oppidum:get-current-user-realm()
  return
    if (empty($realm) or ($realm eq 'EXIST')) then
      globals:collection('persons-uri')//Person[UserProfile/Username eq $user]/Id/text()
    else
      globals:collection('persons-uri')//Person[UserProfile/Remote[@Name eq $realm] eq $user]/Id/text()
};

(:~
 : Gets the user profile of the current user
 : @return A UserProfile element or an empty sequence
 :)
declare function user:get-user-profile() as element()? {
  let $realm := oppidum:get-current-user-realm()
  let $user := oppidum:get-current-user()
  return
    if (empty($realm) or ($realm eq 'EXIST')) then
      globals:collection('persons-uri')//Person/UserProfile[Username eq $user]
    else
      globals:collection('persons-uri')//Person/UserProfile[Remote[@Name eq $realm] eq $user]
};

(:~
 : Converts a sequence of role names into a sequence of function references. 
 : This is mainly to ease up code maintenance
 : @param $roles A sequence of role name strings
 : @return A sequence of function reference strings or the empty sequence
 :)
declare function user:get-function-ref-for-role( $roles as xs:string* ) as xs:string*  {
  if (exists($roles)) then
    globals:collection('global-info-uri')//Description[@Role = 'normative']/Selector[@Name eq 'Functions']/Option[@Role = $roles]/Value/text()
  else
    ()
};
