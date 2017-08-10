xquery version "1.0";
(: --------------------------------------
   Case tracker pilote

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Exports coaches 
   To be called from third party applications like Coach Match

   Implements XML protocol :
   - <Export><All/></Export> : retrieves all coaches
   - <Export><Email>xxx</Email>*</Export> : retrieves all coaches 
      with given e-mail address

   TODO:
   
   October 2015 - (c) Copyright 2015 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

declare namespace xdb = "http://exist-db.org/xquery/xmldb";
declare namespace request = "http://exist-db.org/xquery/request";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../../lib/globals.xqm";
import module namespace services = "http://oppidoc.com/ns/xcm/services" at "../../lib/services.xqm";
import module namespace cas = "http://oppidoc.com/ns/cas" at "../../cas.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

(: ======================================================================
   Returns Coach sample information (Name, Email, Username)
   Useful to align user's login between platforms
   ======================================================================
:)
declare function local:gen-coach-sample( $p as element() ) as element() {
  <Coach> 
    {
    $p/Information/Name,
    $p/Information/Contacts/Email,
    $p//Username
    }
  </Coach>
};

(: ======================================================================
   Returns Coach profile information
   Useful to synchronize user's profile information between platforms
   ======================================================================
:)
declare function local:gen-coach-profile( $p as element() ) as element() {
  <Coach> 
    {
    $p/(Sex | Civility | Name | Country | Contacts)
    }
  </Coach>
};

(: ======================================================================
   Builds regular expression to filters names starting with letter
   or the empty sequence. If letter is not a single letter, then returns 
   a regexp that should match noting.
   ====================================================================== 
:)
declare function local:get-letter-re( $letter as xs:string ) as xs:string? {
  if ($letter ne '') then 
    if (matches($letter, "^[a-zA-Z]$")) then 
      let $l := concat('[', upper-case($letter), lower-case($letter), ']')
      return concat('^', $l, '|(.*\s', $l, ')')
    else
      "^$" (:no name should be empty:)
  else 
    ()
};

(: *** MAIN ENTRY POINT *** :)
let $submitted := oppidum:get-data()
let $errors := services:validate('cctracker', 'cctracker.coaches', $submitted)
return
  if (empty($errors)) then
    let $search := services:unmarshall($submitted)
    let $email := $search/Email/text()
    let $re := if ($search/@Letter) then local:get-letter-re(string($search/@Letter)) else ()
    return
      <Coaches Re="{$re}">
        {
        if ($search/@Format eq 'profile') then 
          for $p in globals:collection('persons-uri')//Person[UserProfile//FunctionRef = '4']
          where (empty($re) or matches($p//LastName, $re))
            and (empty($email) or (normalize-space($p/Information/Contacts/Email) eq $email))
          return local:gen-coach-profile($p)
        else
          for $p in globals:collection('persons-uri')//Person[UserProfile//FunctionRef = '4']
          where (empty($re) or matches($p//LastName, $re))
            and (empty($email) or (normalize-space($p/Information/Contacts/Email) eq $email))
          return local:gen-coach-sample($p)
        }
      </Coaches>
  else
    $errors
