xquery version "1.0";
module namespace sg = "http://oppidoc.com/ns/xcm/supergrid";

declare namespace xdb = "http://exist-db.org/xquery/xmldb";
declare namespace file="http://exist-db.org/xquery/file";
declare namespace transform = "http://exist-db.org/xquery/transform";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../../lib/globals.xqm";

(: ======================================================================
   Executes supergrid transformation on a template specification
   Precondition: - login as "admin" (DBA role)
   ======================================================================
:)
declare function sg:gen-and-save-form( $name as xs:string, $base-url as xs:string ) {
  let $fs-xcm-home := concat(system:get-exist-home(), '/webapp/', globals:app-folder(), '/', $globals:xcm-name)
  let $fs-app-home := concat(system:get-exist-home(), '/webapp/', globals:app-folder(), '/', globals:app-name())
  let $col-uri := concat('/db/www/', globals:app-collection(), '/mesh')
  let $filename := concat($name, '.xhtml')
  let $sg := concat('file://', $fs-xcm-home,'/modules/formulars/supergrid.xsl')
  let $spec := concat('file://', $fs-app-home, '/formulars/', $name, '.xml')
  return 
    if ((oppidum:get-current-user() = 'admin') or (oppidum:get-current-user-groups() = 'developer')) then
      if (doc-available($sg)) then
        if (doc-available($spec)) then
          let $data := fn:doc($spec)
          let $params := <parameters>
                           <param name="xslt.base-url" value="{$base-url}"/>
                           <param name="xslt.base-root" value="{system:get-exist-home()}/"/>
                           <param name="xslt.goal" value="save"/>
                           <param name="xslt.app-name" value="{ globals:app-name()}"/>
                           <param name="xslt.base-formulars" value="webapp/{ globals:app-folder() }/{ globals:app-name() }/formulars/"/>
                           <param name="exist:stop-on-warn" value="yes"/>
                           <param name="exist:stop-on-error" value="yes"/>
                         </parameters>
          return
              let $form := transform:transform($data, $sg, $params)
              let $res := xdb:store($col-uri, $filename, $form)
              return 
                <p>Generated form copied to {$res}</p>
        else
          <p>Could not locate {$spec}</p>
      else
        <p>Could not locate {$sg}</p>
    else
      <p>You must be logged as admin or developer to execute that script (<a href="login?url=forms">login</a>)</p>
};

(: ======================================================================
   Takes a list of formular names (w/o extension) as a + separated list of names
   Generates the formulars using Supergrid transformation and saves them 
   into the '/db/www/{global:app-collection()}/mesh' collection
   ======================================================================
:)
declare function sg:gen-and-save-forms( $names as xs:string, $base-url as xs:string ) {
  let $targets := tokenize($names, '\+')
  return
    if (empty($targets)) then
      <p>Missing or wrong gen parameter</p>
    else
      for $t in $targets
      return
        sg:gen-and-save-form($t, $base-url)
};
