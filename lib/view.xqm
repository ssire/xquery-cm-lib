xquery version "1.0";
(: --------------------------------------
   XQuery Content Management Library

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Helper functions to finalize view generation and Supergrid
   form templates rendering (post-transformation)

   TODO: could be prefixed as site: but actually eXist-DB does not allow
   to declare the same namespace twice

   March 2017 - (c) Copyright 2017 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

module namespace view = "http://oppidoc.com/ns/xcm/view";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";

declare namespace xdb = "http://exist-db.org/xquery/xmldb";
declare namespace xt = "http://ns.inria.org/xtiger";
declare namespace site = "http://oppidoc.com/oppidum/site";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../oppidum/lib/util.xqm";
import module namespace skin = "http://oppidoc.com/oppidum/skin" at "../../oppidum/lib/skin.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "globals.xqm";
import module namespace user = "http://oppidoc.com/ns/xcm/user" at "user.xqm";

(: sets time in minute before kick out in maintenance mode 
   TODO: move to application settings.xml :)
declare variable $view:kick-out-delay := 5;

(: ======================================================================
   Appends value $val to variable $var in XTiger param string
   (e.g. local:insert-param("a=b;c=d"; "a"; "e") returns "a=b e;c=d"
   ====================================================================== 
:)
declare function local:append-param( $var as xs:string, $val as xs:string?, $str as xs:string? ) as xs:string? {
  if ($val) then
    let $bound := concat($var, '=')
    return
      if (contains($str, $bound)) then
        replace ($str, concat($bound, '([^;]*)'), concat($bound, '$1 ', $val))
      else
        concat($str, if($str) then ';' else (), $bound, $val)
  else
    $str
};

(: ======================================================================
   Typeswitch function
   -------------------
   Filters loc and {name}-loc attributes to localize content using a dictionary
   $dict is a dictionary element with a @lang attribute
   ======================================================================
:)
declare function view:localize( $dict as element()?, $source as element(), $sticky as xs:boolean ) as node()*
{
  if ($source/@localized) then (: optimization mainly for search results tables :)
    $source
  else
  element { node-name($source) }
  {
    if ($sticky) then $source/@loc else (),
    for $attr in $source/@*[local-name(.) ne 'loc']
    let $name := local-name($attr)
    return
      if (ends-with($name, '-loc')) then
        let $key := string($attr)
        let $t := $dict/site:Translation[@key = $key]/text()
        return attribute { substring-before($name, '-loc') } { if ($t) then $t else concat('missing [', $key,', lang="', string($dict/@lang), '"]') }
      else if ($source/@*[local-name(.) = concat($name, '-loc')]) then (: skip it :)
        ()
      else
        $attr,
    for $child in $source/node()
    return
      if ($child instance of text()) then
        if ($source/@loc) then
          let $t := $dict/site:Translation[@key = string($source/@loc)]/text()
          return
            if ($t) then
              $t
            else (
              <span style="color:red">
              {
              concat('missing [', string($source/@loc), ', lang="', string($dict/@lang), '"]')
              }
              </span>
            )
        else
          $child
      else if ($child instance of element()) then
        view:localize($dict, $child, $sticky)
      else
        $child (: FIXME: should we care about other stuff like coments ? :)
  }
};

(: ======================================================================
   Returns a localized string for a given $lang and $key
   ======================================================================
:)
declare function view:get-local-string( $lang as xs:string, $key as xs:string ) as xs:string {
  let $res := globals:doc('dico-uri')/site:Dictionary/site:Translations[@lang = $lang]/site:Translation[@key = $key]/text()
  return
    if ($res) then
      $res
    else
      concat('missing [', $key, ', lang="', $lang, '"]')
};

(: ======================================================================
   Implements <site:skin> by inserting CSS links and JS scripts
   The skin selection is defined by the current mesh and the optional 
   skin attribute of the $view element (see also skin.xml)
   ======================================================================
:)
declare function view:skin( $cmd as element(), $view as element() ) as node()*
{
  skin:gen-skin(globals:app-collection(), oppidum:get-epilogue($cmd), $view/@skin),
  if (empty($view/site:links)) then () else skin:rewrite-css-link(globals:app-name(), $view/site:links)
};

(: ======================================================================
   Generates error essages in <site:error>
   ======================================================================
:)
declare function view:error( $cmd as element(), $view as element() ) as node()*
{
  let $resolved := oppidum:render-errors($cmd/@confbase, $cmd/@lang)
  return (
    (: attribute class { 'active' },  :)
    for $m in $resolved/*[local-name(.) eq 'message'] return <p>{$m/text()}</p>
    )
};

(: ======================================================================
   Generates information messages in <site:message>
   Be careful to call session:invalidate() to clear the flash after logout redirection !
   ======================================================================
:)
declare function view:message( $cmd as element() ) as node()*
{
  let $messages := oppidum:render-messages($cmd/@confbase, $cmd/@lang)
  return
    for $m in $messages
    return (
      (: trick because messages are stored inside session :)
      if ($m/@type = "ACTION-LOGOUT-SUCCESS") then session:invalidate() else (),
      <xhtml:p>
        {
        for $a in $m/@*[local-name(.) ne 'type']
        return attribute { concat('data-', local-name($a)) } { string($a) },
        $m/(text()|*)
        }
      </xhtml:p>
    )
};

(: ======================================================================
   Implementation of Supergrid <site:field> extension points in form templates
   Fields marked as filter="copy" are removed or replaced with a constant
   field when readonly flag is set on the template URL.
   ======================================================================
:)
declare function view:field( $cmd as element(), $source as element(), $view as element()* ) as node()* {
  let $goal := request:get-parameter('goal', 'read')
  return
    if (($source/@avoid = $goal) or ($source/@meet and not($source/@meet = $goal))) then
      ()
    else if ($source[@filter = 'copy']) then (: field directly generated from Supergrid :)
      if ($goal = 'read') then
        if ($source[@signature = 'multitext']) then (: sg <MultiText> :)
          <xt:use types="html" param="class=span a-control" label="{$source/xt:use/@label}"/>
        else if ($source[@signature = 'plain']) then (: sg <Plain> :)
          <xt:use types="constant" label="{$source/xt:use/@label}"/>
        else if ($source/xt:use[@types='input']) then (: sg <Input> :)
          let $media := if (contains($source/xt:use/@param, 'constant_media=')) then concat(';constant_media=', substring-after($source/xt:use/@param, 'constant_media=')) else ''
          return
            <xt:use types="constant" param="class=uneditable-input span a-control{$media}">
              { $source/xt:use/@label }
            </xt:use>
        else if ($source/xt:use[@types='text']) then (: sg <Text> :)
          <xt:use types="constant" param="class=sg-multiline uneditable-input span a-control">
            { $source/xt:use/@label }
          </xt:use>
        else if ($source[@signature = 'richtext']) then (: sg <RichText> :)
          <xt:use types="html" param="class=span a-control" label="{$source//xt:repeat/@label}"/>
        else if ($source[@signature = 'append']) then (: sg <Constant> with @Append :)
          <div class="input-append fill">
            <xt:use param="class=uneditable-input fill a-control text-right;" label="{$source/@Tag}" types="constant"></xt:use>
            { $source/div/span }
          </div>
        else
          $source/*
      else
        $source/*
    else
      let $f := $view/site:field[@Key = $source/@Key or (exists(@Prefix) and starts-with($source/@Key, @Prefix))] (: field generated from form.xql :)
      return
        if ($f) then
          if ($f[@filter = 'no']) then
            $f/*
          else
            (: we could use @Size but span12 is compatible anywhere in row-fluid :)
            (: FIXME: for types="constant" you must set the correct span :)
            <xt:use localized="1">
              {
              (: 1. duplicates non-modifiable XTiger plugin attributes :)
              $f/xt:use/(@types|@values|@i18n|@default),
              (: 2. rewrites (or generates) XTiger @param :)
              let $lang := string($cmd/@lang)
              let $ext :=  (
                if ($source/@Required) then 'required=true' else (),
                if ($source/@Placeholder-loc) then concat('placeholder=',view:get-local-string($lang, $source/@Placeholder-loc)) else ()
                )
              return
                if (exists($ext) or exists($source/@Filter)) then
                  attribute { 'param' } {
                    let $filtered := local:append-param('filter', $source/@Filter, $f/xt:use/@param)
                    let $more := if (exists($ext)) then string-join($ext, ';') else ()
                    return
                      if ($filtered) then
                        concat($filtered, ';', $more )
                      else
                        $more
                  }
                else
                  $f/xt:use/@param,
              (: 3. duplicates or generates XTiger @label :)
              if ($f/xt:use/@label) then $f/xt:use/@label else attribute { 'label' } { $source/@Tag/string() },
              (: 4. duplicates text content :)
              $f/xt:use/text()
              }
            </xt:use>
        else
          (: plain constant field (no id, no appended symbol) :)
          <xt:use types="constant" label="{$source/@Tag}" param="class=uneditable-input span a-control"/>
};

(: ======================================================================
   Checks if the application is in maintenance mode with kick out option
   to ask users to logout and kick them out after a minimum notification time.
   Note that Oppidum messages will be rendered immediately after leaving the function
   ======================================================================
:)
declare function view:filter-for-maintenance ( $cmd as element(), $isa_tpl as xs:boolean ) {
  if ( not($isa_tpl)
       and (globals:doc('log-file-uri')/Logs/@KickOut eq 'on')
       and not($cmd/@action = ('logout', 'login')) ) then (: kick out users for maintenance :)

    let $user := oppidum:get-current-user()
    return
      if ((globals:doc('log-file-uri')/Logs/@Hold ne $user) and session:exists()) then
        let $warned := session:get-attribute('kick-out')
        return
          if (empty($warned)) then (
            session:set-attribute('kick-out', current-dateTime()),
            oppidum:add-message('ASK-LOGOUT', concat($view:kick-out-delay, ' minutes'), false())
            )
          else (: tester le temps et delogger de force... :)
            let $ellapsed := current-dateTime() - $warned
            return
              if ($ellapsed > xs:dayTimeDuration(concat('PT', $view:kick-out-delay, 'M'))) then (
                oppidum:add-error('LOGOUT-FOR-MAINTENANCE', (), true()),
                oppidum:add-message('ACTION-LOGOUT-SUCCESS', (), true()),
                xdb:login("/db", "guest", "guest"),
                let $ts := substring(string(current-dateTime()), 1, 19)
                return
                  update insert <Logout User="{$user}" TS="{$ts}">forced</Logout> into globals:doc('log-file-uri')/Logs
                )
              else
                let $minutes := $view:kick-out-delay - minutes-from-duration($ellapsed)
                return
                  oppidum:add-message('ASK-LOGOUT', if ($minutes > 0) then concat($minutes, ' minutes') else 'less than 1 minute', false())
    else
      ()
  else
    ()
};
