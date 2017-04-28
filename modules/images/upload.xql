xquery version "1.0";
(: ------------------------------------------------------------------
   XQuery Content Management Library

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Manages photo upload

   Note that for some images the function get-height, get-width or scale print an error and do
   nothing, This happen for instance if they are in CYMK color space, in that case the script
   does not create a thumb.

   Accepts some parameters from mapping:
   - group (TO BE DONE)
   - logo-thumb-size
   - photo-thumb-size

   Hard-coded parameters:
   - collection to contain images is called 'images'
   - image collection index is called 'index.xml'
   - permissions on both is set to 0744 (rwxw--r--)
   - permission on uploaded image file (TO BE DONE)

   TODO:
   - add photo-max-size parameter
   - add logo-max-size parameter

   !!! Due to an eXist bug, it is not possible yet to pass parameter trough request's parameters.
   Request's attributes are used instead.

   TODO: merge with image.xql and put into persons/photo.xql

   February 2012 - (c) Copyright 2012 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)


import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace sm = "http://exist-db.org/xquery/securitymanager";
import module namespace request = "http://exist-db.org/xquery/request";
import module namespace response = "http://exist-db.org/xquery/response";
import module namespace image = "http://exist-db.org/xquery/image";
import module namespace text = "http://exist-db.org/xquery/text";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace compat = "http://oppidoc.com/oppidum/compatibility" at "../../../oppidum/lib/compat.xqm";
import module namespace misc = "http://oppidoc.com/ns/xcm/misc" at "../../lib/util.xqm";

(: Accepted file extensions normalized to construct an image/"ext" Mime Type string :)
declare variable $accepted-extensions := ('jpeg', 'png', 'gif');

declare function local:get-extension( $file-name as xs:string ) as xs:string
{
  let $unparsed-extension := lower-case( (text:groups($file-name, '\.(\w+)'))[2] )
  return
    replace(replace($unparsed-extension, 'jpg', 'jpeg'), 'tif', 'tiff')
};

(:
  Checks extension is a compatible image type.
  Returns 'ok' or an error message.
:)
declare function local:check-extension( $ext as xs:string ) as xs:string
{
  if ( empty(fn:index-of($accepted-extensions, $ext)) )
  then concat('Les images format ', $ext, ' ne sont actuellement pas supportées')
  else 'ok'
};

(: ======================================================================
   Bootstrap method to create an 'index.xml' file starting at latest index
   inside an images collection that doesn't have it yet (hot plug).
   Returns the first number after the bigger number used to name
   a file inside the collection or 1 if none.
   ======================================================================
:)
declare function local:get-free-resource-name( $col-uri as xs:string ) as xs:integer
{
  let $files := xdb:get-child-resources($col-uri)
  return
    if ((count($files) = 0) or ('index.xml' = $files)) then
       1
    else
      1 + max(
        (0, for $name in $files
        let $nb := text:groups($name, '((\d+)(-logo)?\.\w{2,5})$')[3]
        where $nb castable as xs:integer
        return xs:integer($nb)) )
};

(: ======================================================================
   Returns the current LastIndex in the images collection, creates it
   initialized to 1 if it does not exists. Returns empty sequence if
   the current LastIndex is not usable (this is a serious ERROR).
   ======================================================================
:)
declare function local:get-index( $col-uri as xs:string, $user as xs:string, $group as xs:string ) as node()?
{
  let $perms := 'rwxrwxr--'
  let $doc-uri := concat($col-uri, '/index.xml')
  return (
    if (not(doc-available($doc-uri))) then
      let $start := local:get-free-resource-name($col-uri)
      let $index := <Gallery LastIndex="{$start}"/> (: lazy creation :)
      return
        if (xdb:store($col-uri, 'index.xml', $index)) then
          compat:set-owner-group-permissions(concat($col-uri, '/index.xml'), $user, $group, $perms)
        else
          () (: FIXME: throw-error ? :)
    else
      (),
    doc($doc-uri)/Gallery/@LastIndex
    )[last()]
};

(: ======================================================================
   Creates the 'images' collection
   Returns the path
   ======================================================================
:)
declare function local:create-collection-lazy ( $home-uri as xs:string, $user as xs:string, $group as xs:string ) as xs:string*
{
  let $perms := 'rwxrwxr--'
  let $path := concat($home-uri, '/images')
  return
    if (not(xdb:collection-available($path))) then
      if (xdb:create-collection($home-uri, 'images')) then (
        compat:set-owner-group-permissions($path, $user, $group, $perms),
        $path
        )[last()]
      else
        ()
    else
      $path
};

(: WARNING: as we use double-quotes to generate the Javascript string
   do not use double-quotes in the $msg parameter !
":)
declare function local:gen-error( $msg as xs:string ) as element() {
  let $exec := response:set-header('Content-Type', 'text/html; charset=UTF-8')
  return
    <html>
      <body>
        <script type='text/javascript'>window.parent.finishTransmission(0, "{$msg}")</script>
     </body>
    </html>
};

(:<script type='text/javascript'>window.parent.finishTransmission(1, {{url: "{$full-path}{$id}.{$ext}", resource_id: "{$id}"}})</script>:)
declare function local:gen-success( $id as xs:string, $ext as xs:string ) as element() {
  let
    $full-path := 'images/',
    $exec := response:set-header('Content-Type', 'text/html; charset=UTF-8')
  return
    <html>
      <body>
        <script type='text/javascript'>window.parent.finishTransmission(1, "{$full-path}{$id}.{$ext}")</script>
     </body>
    </html>
};

(: ======================================================================
   Converts a pre-defined request attribute representing a geometry string
   such as '100x200' into a pair of integers. Return empty sequence if
   conversion fail or the attribute is missing from the request.
   ======================================================================
:)
declare function local:get-geometry( $name as xs:string ) as xs:integer*
{
  let $g := request:get-attribute(concat('xquery.', $name))
  return
    if ($g and ($g != 'unset')) then
      let $seq := tokenize($g, 'x')
      return
        if (($seq[1] castable as xs:integer) and ($seq[2] castable as xs:integer)) then
          (xs:integer($seq[1]), xs:integer($seq[2]))
        else
          ()
    else
      ()
};

(: ======================================================================
   Checks if the $data must be downscale according to the $constraint
   Returns a pair where the first item is true() if the $data has been
   downscaled and false otherwise, and the second item is the $data if
   no downscaling was required or either the result of downscaling
   if it succeeded or () otherwise
   ======================================================================
:)
declare function local:downscale( $constraint as xs:string, $id as xs:string, $mime-type as xs:string, $data as xs:base64Binary ) as item()*
{
  let $max-size := local:get-geometry($constraint)
  return
    if (count($max-size) > 1) then
      let $width := image:get-width($data)
      let $height := if ($width) then image:get-height($data) else ()
      let $need-scaling := ($width and $height) and (($width > $max-size[1]) or ($height > $max-size[2]))
      (:let $log := oppidum:debug(('image/upload.xql found image ', string($id), ' dimensions ', string($width), 'x', string($height), ' needs scaling to ', $constraint, '(', string($max-size[1]), 'x', string($max-size[2]), ')', ' is ', string($need-scaling))):)
      return
        if ($need-scaling) then
          let $res := image:scale($data, $max-size, $mime-type)
          return
            if ($res instance of xs:base64Binary) then
              (true(), $res)
            else
              (true(), ()) (: failure while downscaling :)
        else
          (false(), $data) (: no need to dowscale :)
    else
      (false(), $data) (: no need to dowscale :)
};

(: ======================================================================
   Creates the image file into the database and update the LastIndex
   Generates the file name from the $cur-index.
   Pre-condition: $cur-index attribute MUST contain a number
   ======================================================================
:)
declare function local:do-upload(
  $col-uri as xs:string,
  $user as xs:string,
  $group as xs:string,
  $cur-index as node(),
  $data as xs:base64Binary,
  $ext as xs:string ) as element()*
{
  let
    $perms := 'rwxrwxr--',
    $isLogo := request:get-parameter('g', ()) = 'logo',
    $id := string($cur-index),
    $image-id := if ($isLogo) then concat($id, '-logo') else $id,
    $filename := concat($image-id, '.', $ext),
    $mime-type := concat('image/', $ext),
    $log := oppidum:debug(('image/upload.xql creating image ', string($image-id), ' with mime-type ', string($mime-type))),
    $filtered := local:downscale('max-size', $image-id, $mime-type, $data)

  return
    if (($filtered[2] instance of xs:base64Binary) and (xdb:store($col-uri, $filename, $filtered[2], $mime-type))) then
      (
      compat:set-owner-group-permissions(concat($col-uri, '/', $filename), $user, $group, $perms),
      update replace $cur-index with attribute LastIndex { number($id) +1 },
      (: prepare a thumb image if needed - note that we could release the exclusive lock now... :)
      let $cname := if ($isLogo) then 'logo-thumb-size' else 'photo-thumb-size'
      let $thumb := local:downscale($cname, $image-id, $mime-type, $data)
      return
        if ($thumb[1] and ($thumb[2] instance of xs:base64Binary)) then (: write thumb :)
          if (xdb:store($col-uri, concat($image-id, '-thumb.', $ext), $thumb[2], $mime-type)) then
            compat:set-owner-group-permissions(concat($col-uri, '/', $image-id, '-thumb.', $ext), $user, $group, $perms)
          else 
            () (: TODO: return a warning in case of error :)
        else 
          (), (: skip it, either no need to create a thumb or failure :)
      local:gen-success(string($image-id), $ext)
      )[last()]
    else
      local:gen-error("Erreur lors de la sauvegarde de l'image, réessayez avec une autre")
};

(:::::::::::::  BODY  ::::::::::::::)

let $user := xdb:get-current-user()
let $agp := request:get-attribute('xquery.group')
let $group := if ($agp) then $agp else 'site-admin'
return
  let $data := request:get-uploaded-file-data('xt-photo-file')
  return
    if (not($data instance of xs:base64Binary))
    then local:gen-error('Le fichier téléchargé est invalide')
    else
      (: check photo binary stream has compatible MIME-TYPE :)
      let
        $filename := request:get-uploaded-file-name('xt-photo-file'),
        $ext:= local:get-extension($filename),
        $mime-check := local:check-extension($ext)
      return
        if ( $mime-check != 'ok' )
        then local:gen-error($mime-check)
        else
          (: create image collection if it does not exist yet :)
          let $col-uri := local:create-collection-lazy(oppidum:path-to-ref-col(), $user, $group)
          return
            if (not(xdb:collection-available($col-uri)))
              then local:gen-error("Erreur sur le serveur: impossible de créer la collection pour recevoir l'image")
              else
                (: check / create last index :)
                let $cur-index := local:get-index($col-uri, $user, $group)
                return
                  if (not($cur-index castable as xs:integer))
                    then local:gen-error("Erreur sur le serveur: impossible de générer un nom pour stocker l'image")
                    else util:exclusive-lock($cur-index,
                            local:do-upload($col-uri, $user, $group, $cur-index, $data, $ext))
