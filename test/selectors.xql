xquery version "1.0";
(: --------------------------------------
  XQuery Content Management Library

  Creator: Stéphane Sire <s.sire@oppidoc.fr>

  Utility to display all selectors in global-information collection

  November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
  ----------------------------------------------- :)

declare namespace site = "http://oppidoc.com/oppidum/site";
declare namespace xt = "http://ns.inria.org/xtiger";

import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../lib/globals.xqm";
import module namespace form = "http://oppidoc.com/ns/xcm/form" at "../lib/form.xqm";
import module namespace display = "http://oppidoc.com/ns/xcm/display" at "../lib/display.xqm";

declare function local:gen-cell( $name as xs:string, $input as element() ) {
  <div class="row-fluid">
    <div class="span12">
     <div class="a-cell-label a-gap" style="width:200px; margin-left=0">
       <p class="a-cell-legend">{$name}</p>
     </div>
     <div class="a-cell-body" style="margin-left:225px">
      { $input }
      </div>
    </div>
  </div>
};

declare function local:gen-choices( $name as xs:string, $output as xs:string ) {
  <div class="row-fluid">
    <div class="span12">
     <h3>{$name}</h3>
    </div>
  </div>,
  <div class="row-fluid" style="margin-bottom: 1em">
    <div class="span12">
      { 
      $output
      }
    </div>
  </div>
};

let $lang := 'en'
let $selectors := globals:collection('global-info-uri')//Description[@Lang = $lang]//Selector[not(parent::Group)]
return
  <site:view>
    <site:content>
      <div xmlns="http://www.w3.org/1999/xhtml">
        <div class="row-fluid" style="margin-bottom: 1em">
          <h1>Selector elements available in { globals:app-name() } application</h1>
          <p>Use this page to control application selectors generated from Global Information</p>
        </div>
        <h2>Selectors</h2>
        {
        for $s in $selectors
        order by string($s/@Name)
        return
          local:gen-cell(string($s/@Name), form:gen-selector-for(string($s/@Name), $lang, ";multiple=yes;xvalue=ValueRef;typeahead=yes"))
        }
        <h2>Serialization</h2>
        {
        for $s at $i in $selectors
        order by string($s/@Name)
        return
          let $values := for $v in $s//*[local-name(.) eq 'Value']
                         return 
                            concat($v, ' => ', display:gen-name-for($s/@Name, $v, $lang))
          return
            local:gen-choices(string($s/@Name), string-join($values, ', '))
        }
      </div>
      <script type="text/javascript" xmlns="http://www.w3.org/1999/xhtml">
        $axel('body').transform({{'bundlesPath' : $('script[data-bundles-path]').attr('data-bundles-path')}})
      </script>
    </site:content>
  </site:view>


