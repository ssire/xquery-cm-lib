xquery version "1.0";
(: --------------------------------------
   XQuery Content Management Library

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Implementation of the database mapping language (see config/database.xml)

   April 2017 - (c) Copyright 2017 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

module namespace database = "http://oppidoc.com/ns/xcm/database";

declare namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../oppidum/lib/util.xqm";
import module namespace compat = "http://oppidoc.com/oppidum/compatibility" at "../../oppidum/lib/compat.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "globals.xqm";

(: ======================================================================
   Creates the $path hierarchy of collections directly below the $base-uri collection.
   The $path is a relative path not starting with '/'
   The $base-uri collection MUST be available.
   Returns the database URI to the terminal collection whatever the outcome.
   ======================================================================
:)
declare function database:create-collection-lazy ( $base-uri as xs:string, $path as xs:string, $user as xs:string, $group as xs:string, $perms as xs:string ) as xs:string*
{
  let $set := tokenize($path, '/')
  return (
    for $t at $i in $set
    let $parent := concat($base-uri, '/', string-join($set[position() < $i], '/'))
    let $path := concat($base-uri, '/', string-join($set[position() < $i + 1], '/'))
    return
     if (xdb:collection-available($path)) then
       ()
     else
       if (xdb:collection-available($parent)) then
         if (xdb:create-collection($parent, $t)) then
           compat:set-owner-group-permissions($path, $user, $group, $perms)
         else
           ()
       else
         (),
    concat($base-uri, '/', $path)
    )[last()]
};

(: ======================================================================
   Access to Policy element from database.xml configuration
   ====================================================================== 
:)
declare function database:get-policy-for ( $name as xs:string? ) as element()? {
  fn:doc($globals:database-file-uri)//Policy[@Name = $name]
};

(: ======================================================================
   Access to Entity element from database.xml configuration
   ====================================================================== 
:)
declare function database:get-entity-for ( $name as xs:string? ) as element()? {
  fn:doc($globals:database-file-uri)//Entity[@Name = $name]
};

(: ======================================================================
   Applies a Resource policy to the entity given by name
   ====================================================================== 
:)
declare function database:apply-policy-for ( $path as xs:string, $fn as xs:string, $name as xs:string ) as element()? {
  let $entity := database:get-entity-for($name)
  return
    if (exists($entity)) then
      let $policy := database:get-policy-for($entity/Resource/@Policy)
      return
        if (exists($policy)) then
          compat:set-owner-group-permissions(concat($path, '/', $fn), $policy/@Owner, $policy/@Group, $policy/@Perms)
        else
          oppidum:throw-error('UNKOWN-DATABASE-POLICY', $entity/Resource/@Policy)
    else
      oppidum:throw-error('UNKOWN-DATABASE-ENTITY', $name)
};

(: ======================================================================
   Facade using database.xml configuration for create-collection-lazy
   ====================================================================== 
:)
declare function database:create-collection-lazy-for ( $base-uri as xs:string, $path as xs:string, $entity as xs:string ) as xs:string*
{
  let $policy := database:get-policy-for(database:get-entity-for($entity)/Collection/@Policy)
  return
    if (exists($policy)) then
      database:create-collection-lazy($base-uri, $path, $policy/@Owner, $policy/@Group, $policy/@Perms)
    else
      ()
};

(: ======================================================================
   Stores the resource entity into the database as per database.xml
   ======================================================================
:)
declare function database:create-entity( $base-url as xs:string, $name as xs:string, $data as element() ) as element()* {
  let $spec := database:get-entity-for($name)
  let $policy := database:get-policy-for($spec/Resource/@Policy)
  return
    if (empty($policy)) then
      let $col-uri := database:create-collection-lazy-for($base-url, $spec/Collection, $name)
      return
        if ($col-uri) then
          let $res-uri := concat($col-uri, '/', $spec/Resource)
          return
            if (fn:doc-available($res-uri)) then (: append to resource file :)
               update insert $data into fn:doc($res-uri)/*[1]
            else (: first time creation :)
            let $data := element { string($spec/@Root) } { $data }
            let $stored-path := xdb:store($col-uri, string($spec/Resource), $data)
            return
              if(not($stored-path eq ())) then
                compat:set-owner-group-permissions($stored-path, $policy/@Owner, $policy/@Group, $policy/@Perms)
              else
                ()
        else
          ()
    else
      oppidum:throw-error('UNKNOWN-DATABASE-POLICY', $spec/Resource/@Policy)
};
