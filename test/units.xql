xquery version "1.0";
(: --------------------------------------
   XQuery Content Management Library

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Unit Tests

   TODO: identify and apply a unit test framework for XQuery

   November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace site = "http://oppidoc.com/oppidum/site";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../lib/globals.xqm";
import module namespace form = "http://oppidoc.com/ns/xcm/form" at "../lib/form.xqm";
import module namespace display = "http://oppidoc.com/ns/xcm/display" at "../lib/display.xqm";
import module namespace media = "http://oppidoc.com/ns/xcm/media" at "../lib/media.xqm";
import module namespace misc = "http://oppidoc.com/ns/xcm/misc" at "../lib/util.xqm";
import module namespace user = "http://oppidoc.com/ns/xcm/user" at "../../lib/user.xqm";
import module namespace access = "http://oppidoc.com/ns/xcm/access" at "../lib/access.xqm";

declare variable $local:tests := 
  <Tests xmlns="http://oppidoc.com/oppidum/site">
    <Module>
      <Name>Oppidum</Name>
      <Test>string(oppidum:get-command()/@db)</Test>
    </Module>
    <Module>
      <Name>Display</Name>
      <Test><![CDATA[display:gen-name-for('Countries', <Country>FR</Country>, 'en')]]></Test>
      <Test>display:gen-person-name('10', 'en')</Test>
    </Module>
    <Module>
      <Name>Form</Name>
      <Test Format="xml">form:gen-selector-for ('Countries', 'en', '')</Test>
    </Module>
    <Module>
      <Name>Misc</Name>
      <Test Format="xml">misc:gen-current-date('Date')</Test>
      <Test>misc:get-extension('hello')</Test>
      <Test>misc:get-extension('foobar.jpg')</Test>
      <Test Format="xml"><![CDATA[misc:unreference(<Countries><Country>UK</Country><Country>DE</Country></Countries>)]]></Test>
    </Module>
    <Module>
      <Name>User</Name>
      <Test>oppidum:get-current-user-groups()</Test>
      <Test>user:get-current-person-id()</Test>
      <Test Format="xml">user:get-user-profile()</Test>
      <Test>user:get-current-person-id('test')</Test>
      <Test>user:get-function-ref-for-role('admin-system')</Test>
    </Module>
    <Module>
      <Name>Access</Name>
      <Test Format="xml">session:get-attribute('cas-user')</Test>
      <Test>oppidum:get-current-user-realm()</Test>
      <Test>access:check-omnipotent-user()</Test>
      <Test>access:assert-access-rules((), ())</Test>
      <Test><![CDATA[access:assert-rule('test', 'users', <Meet>u:test</Meet>, ())]]></Test>
      <Test><![CDATA[access:assert-rule('test', 'users', <Avoid>u:admin</Avoid>, ())]]></Test>
      <Test><![CDATA[access:assert-access-rules(<Rule xmlns=""><Meet>u:admin</Meet></Rule>, ())]]></Test>
      <Test><![CDATA[access:assert-access-rules(<Rule xmlns=""><Avoid>u:admin</Avoid></Rule>, ())]]></Test>
      <Test>access:check-entity-permissions('delete', 'Person', ())</Test>
      <Test>access:check-entity-permissions('do', 'Something', ())</Test>
    </Module>
    <Module>
      <Name>Media</Name>
      <Test>media:gen-current-user-email(false())</Test>
    </Module>
  </Tests>;

  declare function local:apply-module-tests( $module as element() ) {
    <xhtml:h2>{ $module/site:Name }</xhtml:h2>,
    <xhtml:table class="table">
      {
      for $test in $module/site:Test
      return 
        <xhtml:tr xmlns="">
          <xhtml:td>{ $test/text() }</xhtml:td>
          <xhtml:td style="width:50%">
            {
            if ($test/@Format eq 'xml') then 
              <xhtml:pre xmlns="">
                { 
                fn:serialize(
                  util:eval($test),
                  <output:serialization-parameters>
                    <output:indent value="yes"/>
                  </output:serialization-parameters>
                )
                }
              </xhtml:pre>
            else 
              util:eval($test)
            }
            </xhtml:td>
        </xhtml:tr>
      }
    </xhtml:table>
  };

let $lang := 'en'
return
  <site:view skin="test">
    <site:content>
      <div>
        <div class="row-fluid" style="margin-bottom: 2em">
          <h1>Case Tracker Pilote unit tests</h1>
          {
            for $module in $local:tests/site:Module
            return local:apply-module-tests($module)
          }
        </div>
      </div>
    </site:content>
  </site:view>


