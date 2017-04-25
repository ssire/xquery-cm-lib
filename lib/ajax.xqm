xquery version "1.0";
(: --------------------------------------
   XQuery Content Management Library

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Functions to return responses to Ajax requests to create or update resources
   or to perform other actions with side-effect.

   NOTE: these functions are grouped together in order to decouple the Ajax
   protocols from the rest of the application. This way it should be easier
   to change the protocols used by the Javascript libraries.

   November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

module namespace ajax = "http://oppidoc.com/ns/xcm/ajax";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../oppidum/lib/util.xqm";
import module namespace misc = "http://oppidoc.com/ns/xcm/misc" at "util.xqm";

(: ======================================================================
   Ajax error reporting function for AXEL 'file' plugin module
   ====================================================================== 
:)
declare function ajax:report-file-plugin-error( $msg as xs:string, $status as xs:integer ) as xs:string {
  (: Shouldn't we use oppidum:render-error instead to make error messages configurable ? :)
  let $do1 := response:set-header('Content-Type', 'text/plain; charset=UTF-8')
  let $do2 := response:set-status-code($status)
  return $msg
};

(: ======================================================================
   Ajax success reporting function for AXEL 'file' plugin module
   ====================================================================== 
:)
declare function ajax:report-file-plugin-success( $path as xs:string, $status as xs:integer ) as xs:string {
  let $do1 := response:set-header('Content-Type', 'text/plain; charset=UTF-8')
  let $do2 := response:set-status-code($status)
  return $path
};

(: ======================================================================
   Configures the HTTP response to return a 201 status code with a Location header
   for redirection to a new page. Stores a stikcy message into Oppidum flash
   (3rd argument set to true) to delay its rendering to the next page with an epilogue.
   Changes the HTTP status code to 201
   FIXME: status code should be extracted from the message definition !
   ======================================================================
:)
declare function ajax:report-success-redirect( $type as xs:string, $clues as xs:string*, $loc as xs:string ) as element() {
  let $msg := oppidum:add-message($type, $clues, true())
  return
    (
    response:set-status-code(201),
    response:set-header('Location', $loc),
    $msg
    )
};

(: ======================================================================
   Returns a localized success message.
   As a side effect it may changes the HTTP status code if the message definition has one
   ======================================================================
:)
declare function ajax:report-success( $type as xs:string, $clues as xs:string* ) as element() {
  oppidum:throw-message($type, $clues)
};

(: ======================================================================
   Returns a localized success message and an XML payload
   As a side effect it may changes the HTTP status code if the message definition has one
   ======================================================================
:)
declare function ajax:report-success( $type as xs:string, $clues as xs:string*, $payload as item()* ) {
  let $cmd := request:get-attribute('oppidum.command')
  return
    <success>
      { oppidum:render-message($cmd/@confbase, $type, $clues, $cmd/@lang, true()) }
      <payload>
        { $payload }
      </payload>
    </success>
};

(: ======================================================================
   Returns a localized success message with optional payload and remote command invocation (forward)
   As a side effect it may changes the HTTP status code if the message definition has one
   ======================================================================
:)
declare function ajax:report-success( $type as xs:string, $clues as xs:string*, $payload as item()*, $forward as element()* ) {
  let $cmd := request:get-attribute('oppidum.command')
  return
    <success>
      { oppidum:render-message($cmd/@confbase, $type, $clues, $cmd/@lang, true()) }
      { if ($payload) then <payload>{ $payload }</payload> else () }
      { if ($forward) then $forward else () }
    </success>
};

(: ======================================================================
   Generates an error element to report an error later on either in the epilogue
   or by calling explicitly ajax:report-validation-errors() or ajax:report-errors()
   if called from an Ajax request handler.
   ======================================================================
:)
declare function ajax:throw-error( $type as xs:string, $clues as xs:string* ) as element() {
  oppidum:throw-error( $type, $clues)
};

(: ======================================================================
   Converts errors raised during a script execution into an XML error response
   to return to the client for notifying the user.
   ======================================================================
:)
declare function ajax:report-validation-errors( $errors as element()* ) as element() {
  let $explain :=
    string-join(
      for $e in $errors
      return $e/message/text(), ', ')
  return
    oppidum:throw-error('VALIDATION-FAILED', $explain)
};
