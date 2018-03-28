xquery version "3.0";
(: ------------------------------------------------------------------
   XQuery Content Management Library

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Interaction with services configured in services.xml

   July 2015 - (c) Copyright 2015 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

module namespace services = "http://oppidoc.com/ns/xcm/services";

declare namespace request = "http://exist-db.org/xquery/request";

declare namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "globals.xqm";

(: ======================================================================
   Utility function which can be used to decode responses with @encoding
   set to "URLEncoded" such as from .NET applications
   ====================================================================== 
:)
declare function services:decode( $source as element()? ) as element()? {
  if ($source/@encoding eq 'URLEncoded') then
    element { node-name($source) }
    {
    $source/@*,
    util:parse(xdb:decode-uri($source))
    }
  else
    element { node-name($source) }
    {
    $source/@*,
    for $child in $source/node()
    return
      if ($child instance of text()) then
        $child
      else
        services:decode($child)
    }
};

(: ======================================================================
   Returns a service request envelope ready to send to service producer
   This can be used for instance to generate a request to be sent with Ajax 
   from a client page consuming the service
   ====================================================================== 
:)
declare function services:gen-envelope-for ( $service-name as xs:string?, $end-point-name as xs:string?, $payload as item()* ) as element()? {
  let $service := globals:doc('services-uri')//Service[Id eq $service-name]
  return services:marshall($service, $payload)
};

(: ======================================================================
   Reads a Key element associated with a service consumer end-point 
   to send it to the service producer within the payload so that the producer
   can create 1-1 associations between consumers and internal resources
   ======================================================================
:)
declare function services:get-key-for ( $service-name as xs:string?, $end-point-name as xs:string? ) as element()? {
  let $service := globals:doc('services-uri')//Service[Id eq $service-name]
  let $end-point := $service/EndPoint[Id eq $end-point-name]
  return $end-point/Key
};

(: ======================================================================
   Converts a Key element received with some payload on a service producer
   end-point into a KeyRef element to some internal resource in the application
   ====================================================================== 
:)
declare function services:get-key-ref-for ( $service-name as xs:string?, $end-point-name as xs:string?, $key as element()? ) as element()? {
  let $service := globals:doc('services-uri')//Service[Id eq $service-name]
  let $end-point := $service/EndPoint[Id eq $end-point-name]
  return 
    if ($key) then $end-point/Keys/KeyRef[@For eq $key] else ()
};

(: ======================================================================
   Internal utility to generate a service label for error messages
   ======================================================================
:)
declare function local:gen-service-name( $service as xs:string?, $end-point as xs:string? ) as xs:string {
  concat('"', $end-point, '" end-point of service "', $service, '"')
};

(: ======================================================================
   Marshalls a single element payload content to invoke a given service using
   the service API model (i.e. including authorization token as per services.xml)
   ======================================================================
:)
declare function services:marshall( $service as element()?, $payload as item()* ) as element() {
  <Service>
    { $service/AuthorizationToken }
    <Payload>{ $payload }</Payload>
  </Service>
};

(: ======================================================================
   Retrieves submitted payload element(s) from raw submitted data
   To be called when data has been marshalled using services:marshall
   (for instance by calling services:post)
   ======================================================================
:)
declare function services:unmarshall( $submitted as element()? ) as element()* {
  $submitted/Payload/*
};

(: ======================================================================
   POST XML payload to an URL address. Low-level implementation

   Returns an Oppidum error in case service is not configured properly
   in services.xml or is not listening or if the response payload contains
   an error raised with oppidum:throw-error (whatever its status code)
   or, finally, if the response from the POST returns a status code not expected

   TODO:
   - better differentiate error messages (incl. 404)
   - detect XQuery errors dumps in responses (like oppidum.js) and relay them
   - actually oppidum:throw-error in the service with a status code not in 200 
     results in an <httpclient:body type="text" encoding="URLEncoded"/>
     and a statusCode="500" !
   ======================================================================
:)
declare function services:post-to-address ( $address as xs:string, $payload as item()?, $expected as xs:string+, $debug-name as xs:string ) as element()? {
  if ($address castable as xs:anyURI) then
    let $uri := xs:anyURI($address)
    let $headers := ()
    let $res := httpclient:post($uri, $payload, false(), $headers)
    let $status := string($res/@statusCode)
    return
      if ($res//error/message) then (: relay Oppidum type error response :)
        oppidum:throw-error('SERVICE-INTERNAL-ERROR', ($debug-name, concat(' (status ', $status, ') ', string($res//error/message))))
      else if ($status eq '500' and (string($res) eq 'Connection+refused')) then
        oppidum:throw-error('SERVICE-NOT-RESPONDING', $debug-name)
      else if ($status = $expected) then
        $res
      else
        let $raw := normalize-space(string($res))
        let $response := if ($raw eq '') then 'empty response' else $raw
        return
          oppidum:throw-error('SERVICE-ERROR', ($debug-name, concat($response,' (status ' , $res/@statusCode,')')))
  else
    oppidum:throw-error('SERVICE-MALFORMED-URL', ($debug-name, $address))
};

(: ======================================================================
   POST XML payload to a service and an end-point elements
   ======================================================================
:)
declare function services:post-to-service-imp ( $service as element()?, $end-point as element()?, $payload as item()?, $expected as xs:string+ ) as element()? {
  if ($service and $end-point) then
    let $service-name := local:gen-service-name($service/Name/text(), $end-point/Name/text())
    let $envelope := services:marshall($service, $payload)
    return services:post-to-address($end-point/URL/text(), $envelope, $expected, $service-name)
  else
    oppidum:throw-error('SERVICE-MISSING', 'undefined')
};

(: ======================================================================
   Log on demand (see settings.xml) and return service response
   FIXME: log anyway in case of failure ?
   ====================================================================== 
:)
declare function local:log( $service as element(), $end-point as element(), $payload as element()?, $res as element()? ) as element()? {
  let $debug := globals:doc('settings-uri')/Settings/Services/Debug
  let $log := $debug/Service[Name eq $service/Id][not(EndPoint) or EndPoint eq $end-point/Id]
  return
    if (exists($log)) then
      if (fn:doc-available('/db/debug/services.xml')) then
        let $archive := 
          <service date="{ current-dateTime() }">
            {
            attribute { 'status' } { 
              if (exists(globals:doc('settings-uri')/Settings/Services/Disallow/Service[Name eq $service/Id][not(EndPoint) or EndPoint eq $end-point/Id])) then
                'unplugged'
              else if (local-name($res) eq 'error') then
                'error'
              else
                'done'
            },
            <To>{ $service/Id/text() } / { $end-point/Id/text() }</To>,
            <Request method="POST" url="{ $end-point/URL }">{ services:marshall($service, $payload) }</Request>,
            <Response>
              {
              if (exists($log/Logger/Assert)) then (: implements Logger syntax - only 1 for now :)
                if (util:eval($log/Logger/Assert)) then
                  try { util:eval($log/Logger/Format) } catch * { $res }
                else
                  $res
              else
                $res
              }
            </Response>
            }
          </service>
        return (
          try { update insert $archive into fn:doc('/db/debug/services.xml')/Debug }
          catch * { () },
          $res
          )
      else
        $res
    else
      $res
};

(: ======================================================================
   POST XML payload to named end point of named service
   ======================================================================
:)
declare function services:post-to-service ( $service-name as xs:string, $end-point-name as xs:string, $payload as element()?, $expected as xs:string+ ) as element()? {
  let $service := globals:doc('services-uri')//Service[Id eq $service-name]
  let $end-point := $service/EndPoint[Id eq $end-point-name]
  let $block := globals:doc('settings-uri')/Settings/Services/Disallow
  return
    if ($service and $end-point) then
      (: filters service call through settings.xml :)
      if ($block/Service[Name eq $service-name][not(EndPoint) or EndPoint eq $end-point-name]) then
        (: fake success - only useful for services that do not return payload :)
        local:log($service, $end-point, $payload, <success status="unplugged"/>)
      else
        local:log($service, $end-point, $payload,
          services:post-to-service-imp($service, $end-point, $payload, $expected))
    else
      oppidum:throw-error('SERVICE-MISSING', local:gen-service-name($service-name, $end-point-name))
};

(: ======================================================================
   Implements submitted data validation according to the service API model :
   - checks service is properly configured in services.xml
   - checks optional AuthorizationToken as per services.xml
   Returns the empty sequence if the service call is regular or an Oppidum
   error message otherwise
   ======================================================================
:)
declare function services:validate ( $service-name as xs:string, $end-point as xs:string, $submitted as item()? ) as element()? {
  let $service := globals:doc('services-uri')//Providers/Service[Id eq $service-name][EndPoint/Id eq $end-point]
  return
    if (empty($service)) then
      oppidum:throw-error('SERVICE-MISSING', local:gen-service-name($service-name, $end-point))
    else if (not($submitted instance of element())) then
      oppidum:throw-error('SERVICE-ERROR', (local:gen-service-name($service-name, $end-point), 'Wrong data type'))
    else if ($service/AuthorizationToken and (string($submitted/AuthorizationToken) ne string($service/AuthorizationToken))) then
      oppidum:throw-error('SERVICE-FORBIDDEN', local:gen-service-name($service-name, $end-point))
    else
      ()
};

(: ======================================================================
   Returns a localized success message with optional payload and remote command invocation (forward)
   As a side effect it may changes the HTTP status code if the message definition has one
   ======================================================================
:)
declare function services:report-success( $type as xs:string, $clues as xs:string*, $payload as item()* ) {
  let $cmd := request:get-attribute('oppidum.command')
  return
    <success>
      { oppidum:render-message($cmd/@confbase, $type, $clues, $cmd/@lang, true()) }
      { if ($payload) then <payload>{ $payload }</payload> else () }
    </success>
};

declare function services:get-hook-address( $service as xs:string, $end-point as xs:string ) as xs:string*  {
  services:get-hook-address($service, $end-point, ())
};

declare function services:get-hook-address( $service as xs:string, $end-point as xs:string, $vars as xs:string* ) as xs:string*  {
  let $hook := globals:doc('services-uri')//Hooks/Service[Id eq $service]/EndPoint[Id eq $end-point]
  return
    if ($hook) then
      concat($hook/URL/text(), $vars[1])
    else
      ()
};

(: ======================================================================
   Utility to read and transform a service configuration file before
   posting it to configure a service
   Currently it implements a very limited Append/Hook instruction
   TODO: replace Append/Hook with a in-file Hook element filtering (?)
   ======================================================================
:)
declare function local:read-and-transform-file( $file-uri as xs:string, $transform as element() ) as element() {
  let $data := fn:doc($file-uri)
  let $root := $data/*[1]
  return
    element { local-name($root) } {
      $root/(*|@*),
      for $hook in $transform/Append/Hook
      return
        let $address := services:get-hook-address($hook/@Service, $hook/@EndPoint)
        return
          if ($address) then
            <Hook>{ $hook/@Name, $address }</Hook>
          else
            <MISSING>Service "{ string($hook/@Service) }" + EndPoint "{ string($hook/@EndPoint) }"</MISSING>
    }
};

(: ======================================================================
   Runs all Deploy tasks in the application services.xml file
   Returns a success or error element for each task

   To be called from deployment scripts such as scripts/deploy.xql
   when deploying / updating external services

   Limitations:
   - currently implements only POST elements
   - currently resources are read from file system
   ======================================================================
:)
declare function services:deploy ( $base-dir as xs:string ) as element()* {
  if (count(globals:doc('services-uri')//Deploy/POST) > 0) then
    for $task in globals:doc('services-uri')//Deploy/POST
    return
      if (local-name($task) eq 'POST') then
        let $file-uri := concat('file://', $base-dir, '/', $task/Resource/File)
        let $expected := tokenize($task/@Expected, ',')
        return
          if (doc-available($file-uri)) then
            let $payload := local:read-and-transform-file($file-uri, $task/Resource)
            let $res := services:post-to-service-imp($task/ancestor::Service, $task/ancestor::EndPoint, $payload, $expected)
            return
              if (local-name($res) ne 'error') then
                <success>{ $task/Description/text() } ({ $task/Resource/File/text() }) deployed : { $res//success/message/text() }</success>
              else
                $res
          else
            <error>Could not find resource "{ $task/Resource/File/text() }" to deploy</error>
      else
        <error>Unsupported Deploy task { local-name($task) }</error>
  else
    <error>No service to deploy or "settings.xml" missing in application "config" collection</error>
};
