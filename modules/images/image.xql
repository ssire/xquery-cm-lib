xquery version "1.0";        
(: --------------------------------------
   Oppidum module: image 

   Author: Stéphane Sire <s.sire@free.fr>

   Serves images from the database. Sets a Cache-Control header.

   TODO:
   - improve Cache-Control (HTTP 1.1) with Expires / Date (HTTP 1.0)
   - (no need for must-revalidate / Last-Modified since images never change)

   TODO: merge with upload.xql and put into persons/photo.xql

   March 2012 - (c) Copyright 2012 Oppidoc SARL. All Rights Reserved.
   -------------------------------------- :)

import module namespace request = "http://exist-db.org/xquery/request";
import module namespace response = "http://exist-db.org/xquery/response";

declare option exist:serialize "method=text media-type=text/plain indent=no";

let $cmd := request:get-attribute('oppidum.command')
let $image-uri := concat($cmd/resource/@db, '/', $cmd/resource/@collection, '/', $cmd/resource/@resource, '.', $cmd/@format)
return
  if (util:binary-doc-available($image-uri)) 
  then  
    let $image := util:binary-doc($image-uri)
    return (
      response:set-header('Pragma', 'x'),
      response:set-header('Cache-Control', 'public, max-age=900000'),
      response:stream-binary($image, concat('image/', $cmd/@format))
    )
  else
    ( "Erreur 404 (pas d'image)", response:set-status-code(404)  )
