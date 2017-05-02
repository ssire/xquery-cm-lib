xquery version "1.0";
(: ------------------------------------------------------------------
   XQuery Content Management Library

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Generation of formulars from their XML specification files 
   in the file system, the result is stored inside the mesh 
   collection inside the database.

   May 2014 - (c) Copyright 2014 Oppidoc SARL. All Rights Reserved. 
   ------------------------------------------------------------------ :)
declare namespace request = "http://exist-db.org/xquery/request";

import module namespace sg = "http://oppidoc.com/ns/xcm/supergrid" at "install.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../../lib/globals.xqm";

declare option exist:serialize "method=xml media-type=application/xml";

(: ======================================================================
   Returns the name of the folder inside projects folder where to look
   for the supergrid.xsl transformation 
   ====================================================================== 
:)
declare function local:get-folder-name() as xs:string {
  let $sg-folder := request:get-attribute('xquery.sg-folder')
  return
    if (empty($sg-folder)) then
      $globals:xcm-name
    else if (starts-with($sg-folder, 'eval:')) then
      util:eval(substring-after($sg-folder, 'eval:'))
    else
      $sg-folder
};

let $targets := request:get-parameter('gen', '')
let $cmd := request:get-attribute('oppidum.command')
return
  sg:gen-and-save-forms($targets, $cmd/@base-url, local:get-folder-name())
