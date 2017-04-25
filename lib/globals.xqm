xquery version "1.0";
(: --------------------------------------
   XQuery Content Management Library

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Global variables or utility functions for the application

   PRE-REQUISITE

     Store your application globals.xml at $globals:globals-uri

   IMPORTANT WARNING

     Due to a current limitation in eXist-DB (2.2) if you import several modules
     with the same namespace (like globals) first one will be the only one imported
     consequently duplicate all of this module code inside your application own globals.xqm

   April 2017 - (c) Copyright 2017 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

module namespace globals = "http://oppidoc.com/ns/xcm/globals";

(: MUST be aligned with your application's lib/globals.xqm :)
declare variable $globals:xcm-name := 'xcm';
declare variable $globals:globals-uri := '/db/www/xcm/config/globals.xml';

declare function globals:app-name() as xs:string {
  fn:doc($globals:globals-uri)//Global[Key eq 'app-name']/Value
};

declare function globals:app-folder() as xs:string {
  fn:doc($globals:globals-uri)//Global[Key eq 'app-folder']/Value
};

declare function globals:app-collection() as xs:string {
  fn:doc($globals:globals-uri)//Global[Key eq 'app-collection']/Value
};

(:~
 : Returns the selector from global information that serves as a reference for
 : a given selector enriched with meta-data.
 : @return The normative Selector element or the empty sequence
 :)
declare function globals:get-normative-selector-for( $name ) as element()? {
  fn:collection(fn:doc($globals:globals-uri)//Global[Key eq 'global-info-uri']/Value)//Description[@Role = 'normative']/Selector[@Name eq $name]
};

(: ******************************************************************* :)
(:                                                                     :)
(: Below this point copy content to your application's lib/globals.xqm :)
(:                                                                     :)
(: ******************************************************************* :)

declare function globals:doc-available( $name ) {
  fn:doc-available(fn:doc($globals:globals-uri)//Global[Key eq $name]/Value)
};

declare function globals:collection( $name ) {
  fn:collection(fn:doc($globals:globals-uri)//Global[Key eq $name]/Value)
};

declare function globals:doc( $name ) {
  fn:doc(fn:doc($globals:globals-uri)//Global[Key eq $name]/Value)
};

