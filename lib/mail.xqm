xquery version "1.0";
(: ------------------------------------------------------------------
   XQuery Content Management Library

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Mail utilities to generate notifications and to archive mail messages

   Variables are defined in config/variables.xml

   Extra variables (not defined in config/variables.xml) may include : 

   Mail_To, Mail_CC, Mail_From, Mail_From, First_Name, Last_Name, Link_To_Form,
   Login, Password, Action_Verb, Status_Name, etc.

   January 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved. 
   ------------------------------------------------------------------ :)

module namespace email = "http://oppidoc.com/ns/xcm/mail";

declare namespace xdb = "http://exist-db.org/xquery/xmldb";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "globals.xqm";
import module namespace display = "http://oppidoc.com/ns/xcm/display" at "display.xqm";
import module namespace media = "http://oppidoc.com/ns/xcm/media" at "media.xqm";
import module namespace services = "http://oppidoc.com/ns/xcm/services" at "services.xqm";
import module namespace alert = "http://oppidoc.com/ns/xcm/alert" at "../modules/workflow/alert.xqm";
import module namespace workflow = "http://oppidoc.com/ns/xcm/workflow" at "../modules/workflow/workflow.xqm";
import module namespace enterprise = "http://oppidoc.com/ns/xcm/enterprise" at "../modules/enterprises/enterprise.xqm";

(: ======================================================================
   Generic function to generate e-mail template variables for a given 
   template name and given a case and an activity and extra variables
   Variables are resolved FIRST in the extra variables and SECOND 
   using config/variables.xml definitions which must be kept up to date
   ====================================================================== 
:)
declare function email:gen-variables-for( 
  $name as xs:string,
  $lang as xs:string,
  $subject as element()?,
  $object as element()?,
  $extras as element()* ) as element() 
{
  <vars>
    {
    let $template := globals:collection('global-info-uri')/Emails/*[@Name eq $name][@Lang eq $lang]
    return
      if ($template) then 
        let $keys := tokenize(string($template), '@@')[position() mod 2 = 0]
        let $defs := globals:doc('variables-uri')/Variables
        return
          for $k in $keys
          return
            if ($extras[@name eq $k]) then
              $extras[@name eq $k]
            else if ($defs/Variable[Name eq $k]) then
              let $d := $defs/Variable[Name eq $k]
              return 
                if ($d/Name[. eq $k]/preceding-sibling::Name) then
                  (: multi-variables definitions are generated at first pass :)
                  ()
                else
                  let $custom := util:import-module(
                                  xs:anyURI("http://oppidoc.com/ns/application/custom"),
                                  'custom',
                                  xs:anyURI(concat(system:get-exist-home(), '/webapp/', globals:app-folder(), '/', globals:app-name(), '/app/custom.xqm'))
                                )
                  return
                    let $res := util:eval($d/Expression/text())
                    return
                      if ($res instance of element()+) then
                        $res
                      else
                        <var name="{ $k }">{ string($res) }</var>
            else
              <var name="{ $k }">MISSING ({ $k })</var>
      else
        ()
      }
  </vars>
};

(: ======================================================================
   Generates an Email model from the name template and the variables
   ======================================================================
:)
declare function local:render-template( $tag as xs:string, $name as xs:string, $lang as xs:string, $subject as element()?, $object as element()?, $extras as element()* ) as element() {
  let $languages := media:select-languages($lang)
  return
    if (count($languages) = (0, 1)) then
      media:render-template($tag, $name, email:gen-variables-for($name, $lang, $subject, $object, $extras), $lang)
    else
      media:merge-email-or-alert(
        for $l in $languages
        return
          media:render-template($tag, $name, email:gen-variables-for($name, $l, $subject, $object, $extras), $l)
        )
};

(: ======================================================================
   Generates Email model with variables expansion
   ====================================================================== 
:)
declare function email:render-email( 
  $name as xs:string,
  $lang as xs:string,
  $subject as element()?,
  $object as element()?,
  $extras as element()* ) as element() 
{
  local:render-template('Email', $name, $lang, $subject, $object, $extras)
};

(: ======================================================================
   Generates Alert model with variables expansion
   ====================================================================== 
:)
declare function email:render-alert( 
  $name as xs:string,
  $lang as xs:string,
  $subject as element()?,
  $object as element()?,
  $extras as element()* ) as element() 
{
  local:render-template('Alert', $name, $lang, $subject, $object, $extras)
};

(: ======================================================================
   Generates Alert model with variables expansion (version w/o extras)
   ====================================================================== 
:)
declare function email:render-alert( 
  $name as xs:string,
  $lang as xs:string,
  $subject as element()?,
  $object as element()?) as element() 
{
  local:render-template('Alert', $name, $lang, $subject, $object, ())
};

