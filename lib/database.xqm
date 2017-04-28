xquery version "1.0";
(: --------------------------------------
   XQuery Content Management Library

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Implementation of the database mapping language (see config/database.xml)

   TODO:
   - implement @Sharding="by-bucket(4,50)"

   April 2017 - (c) Copyright 2017 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

module namespace database = "http://oppidoc.com/ns/xcm/database";

declare namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../oppidum/lib/util.xqm";
import module namespace compat = "http://oppidoc.com/oppidum/compatibility" at "../../oppidum/lib/compat.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "globals.xqm";

(: ======================================================================
   Collection path sharding algorithm
   Returns a "YYYY/MM/key" string based on current date
   ====================================================================== 
:)
declare function local:by-year-month-key( $key as item() ) {
  let $date :=  substring(string(current-dateTime()), 1, 10)
  let $year := substring($date, 1, 4)
  let $month := substring($date, 6, 2)
  return
    concat($year, '/', $month, '/', $key)
};

(: ======================================================================
   Creates the $path hierarchy of collections directly below the $db-uri collection.
   The $path is a relative path not starting with '/'
   The $db-uri collection MUST be available.
   Returns the database URI to the terminal collection whatever the outcome.
   ======================================================================
:)
declare function database:create-collection-lazy ( $db-uri as xs:string, $path as xs:string, $user as xs:string, $group as xs:string, $perms as xs:string ) as xs:string*
{
  let $set := tokenize($path, '/')
  return (
    for $t at $i in $set
    let $parent := concat($db-uri, '/', string-join($set[position() < $i], '/'))
    let $path := concat($db-uri, '/', string-join($set[position() < $i + 1], '/'))
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
    concat($db-uri, '/', $path)
    )[last()]
};

(: ======================================================================
   Access to Policy element from database.xml configuration
   ====================================================================== 
:)
declare function database:get-policy-for ( $name as xs:string? ) as element()? {
  globals:doc('database-file-uri')//Policy[@Name = $name]
};

(: ======================================================================
   Access to Entity element from database.xml configuration
   ====================================================================== 
:)
declare function database:get-entity-for ( $name as xs:string? ) as element()? {
  globals:doc('database-file-uri')//Entity[@Name = $name]
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
declare function database:create-collection-lazy-for ( $db-uri as xs:string, $path as xs:string, $entity as xs:string ) as xs:string*
{
  let $policy := database:get-policy-for(database:get-entity-for($entity)/Collection/@Policy)
  return
    if (exists($policy)) then
      database:create-collection-lazy($db-uri, $path, $policy/@Owner, $policy/@Group, $policy/@Perms)
    else
      ()
};

(: ======================================================================
   Stores the resource entity into the database as per database.xml
   This is the version to use with a Root attribute of the Resource element
   to store all the entities in a single file
   Returns the empty sequence or throws an Oppidum errror
   ======================================================================
:)
declare function database:create-entity( $db-uri as xs:string, $name as xs:string, $data as element() ) as element()? {
  let $spec := database:get-entity-for($name)
  let $policy := database:get-policy-for($spec/Resource/@Policy)
  return
    if (exists($policy)) then
      let $col-uri := database:create-collection-lazy-for($db-uri, $spec/Collection, $name)
      return
        if ($col-uri) then
          let $res-uri := concat($col-uri, '/', $spec/Resource)
          return
            if (fn:doc-available($res-uri)) then (: append to resource file :)
               update insert $data into fn:doc($res-uri)/*[1]
            else (: first time creation :)
              let $store := element { string($spec/Resource/@Root) } { $data }
              let $stored-path := xdb:store($col-uri, string($spec/Resource), $store)
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

(: ======================================================================
   Generates a new key to store a resource according to database.xml
   ====================================================================== 
:)
declare function database:make-new-key-for( $db-uri as xs:string, $name as xs:string ) as item()? {
  let $spec := database:get-entity-for($name)
  let $pivot := string($spec/Resource/@Pivot)
  let $expr := concat("fn:collection('", $db-uri, "/", $spec/Collection, "')", $pivot)
  return
    util:eval (
      concat(
        "if (exists(", $expr, ")) then ",
        "max(for $k in ", $expr,
        " return if ($k castable as xs:integer) then number($k) else 0) + 1",
        " else 1"
        )
    )
};

(: ======================================================================
   Creates collection to store given type of entity with a given key
   Returns a <success> or <error> element
   ====================================================================== 
:)
declare function database:create-collection-for-key ( 
  $db-uri as xs:string, 
  $entity as xs:string, 
  $key as item()? ) as element()
{
  if (exists($key)) then
    let $spec := database:get-entity-for($entity)
    let $policy := database:get-policy-for($spec/Collection/@Policy)
    return
      if (exists($policy)) then
        let $path := if ($spec/Collection/@Sharding eq 'by-year-month-key') then
                       concat($spec/Collection, '/', local:by-year-month-key($key))
                     else
                       $spec/Collection
        return 
          <success>{ database:create-collection-lazy($db-uri, $path, $policy/@Owner, $policy/@Group, $policy/@Perms) }</success>
      else
        oppidum:throw-error('UNKNOWN-DATABASE-POLICY', $spec/Collection/@Policy)
  else
    oppidum:throw-error('MISSING-DATABASE-KEY', $entity)
};

(: ======================================================================
   Stores the resource entity into the database as per database.xml
   This is the version to use to create one file per resource using 
   a sharding algorithm
   Returns a success element or throws an Oppidum error
   ======================================================================
:)
declare function database:create-entity-for-key( 
  $db-uri as xs:string, 
  $name as xs:string, 
  $data as element(), 
  $key as item()? ) as element() 
{
  if (exists($key)) then
    let $spec := database:get-entity-for($name)
    let $policy := database:get-policy-for($spec/Resource/@Policy)
    return
      if (exists($policy)) then
        let $result := database:create-collection-for-key($db-uri, $name, $key)
        return
          if (local-name($result) eq 'success') then 
            let $res-uri := concat($result, '/', $spec/Resource)
            return
              if (fn:doc-available($res-uri)) then (: append to resource file : should we support this ? :)
                (
                update insert $data into fn:doc($res-uri)/*[1],
                <success>{ $res-uri }</success>
                )
              else (: first time creation :)
                let $store := if (exists($spec/Resource/@Root)) then 
                                element { string($spec/Resource/@Root) } { $data } 
                              else 
                                $data
                let $stored-path := xdb:store($result, string($spec/Resource), $store)
                return
                  if(not($stored-path eq ())) then
                    <success>
                      {
                      compat:set-owner-group-permissions($stored-path, $policy/@Owner, $policy/@Group, $policy/@Perms),
                      $stored-path
                      }
                    </success>
                  else
                    oppidum:throw-error('DB-WRITE-INTERNAL-FAILURE', ())
          else
            $result
      else
        oppidum:throw-error('UNKNOWN-DATABASE-POLICY', $spec/Resource/@Policy)
  else
    oppidum:throw-error('MISSING-DATABASE-KEY', $name)
};