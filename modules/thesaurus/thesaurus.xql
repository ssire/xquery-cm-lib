xquery version "1.0";
(: --------------------------------------
   XQuery Content Management Library

   Author: Stéphane Sire <s.sire@oppidoc.fr>

   Localization

   Utility to allow simple and double entries lists editing to localize global-information.xml

   The algorithm uses the 'fr' version as a referential, hence the 'de' version must be aligned
   on the same keys, any extra keys will not be exported.

   April 2014, June 2017 - (c) Copyright 2014 - 2017 Oppidoc SARL. All Rights Reserved.
   -------------------------------------- :)

declare namespace th = "http://platinn.ch/cocahing/thesaurus";

declare option exist:serialize "method=xml media-type=application/xml";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../../lib/globals.xqm";
import module namespace ajax = "http://oppidoc.com/ns/xcm/ajax" at "../../lib/ajax.xqm";
import module namespace cache = "http://oppidoc.com/ns/xcm/cache" at "../../lib/cache.xqm";

(: FIXME: compute dynamically :)
declare variable $th:simple-lists :=
  <th:SingleEntryLists>
    <th:List id="1" Root="Countries" />
    <th:List id="2" Root="Functions" />
    <th:List id="3" Root="Services" />
    <th:List id="4" Root="Sizes" />
  </th:SingleEntryLists>;

(: FIXME: compute dynamically :)
declare variable $th:double-lists :=
  <th:DoubleEntryLists>
    <th:List id="1" Root="CaseImpacts" />
    <th:List id="2" Root="DomainActivities" />
    <th:List id="3" Root="TargetedMarkets" />
  </th:DoubleEntryLists>;

(: ======================================================================
   Returns the Selector element for a data model with $lang referential
   $spec must come from $th:simple-lists
   ======================================================================
:)
declare function local:get-selector( $name as xs:string, $lang as xs:string ) as element()? {
  let $defs := globals:collection('global-info-uri')//Description[@Lang=$lang]/Selector[@Name eq $name]     return
    $defs
};

(: ======================================================================
   Genreates simple or double entry list data model for editing
   ======================================================================
:)
declare function local:gen-selector-for-editing-I( $id as xs:string, $list-spec as element() )
{
  let $spec := $list-spec/th:List[@id = $id]
  let $selector := local:get-selector($spec/@Root, 'en')
  return
    local:gen-simple-list-I($selector, $spec)
};

(: ======================================================================
   Turns $root simple list (raw Global Information sub-tree) into a generic simple list
   Note this is also called when generating a generic double list
   TODO: make languages independant
   ======================================================================
:)
declare function local:gen-simple-list-I( $root as element()?, $spec as element() ) as element()
{
  <th:List>
    {
    for $item in $root/Option
    let $item-fr := local:get-selector($spec/@Root, 'fr')/Option[Value = $item/Value]
    let $item-de := local:get-selector($spec/@Root, 'de')/Option[Value = $item/Value]
    return
      <th:Item>
        <th:Key>{$item/Value/text()}</th:Key>
        <th:Label Lang="en">{ $item/Name/text() }</th:Label>
        {
        if ($item-fr) then
          <th:Label Lang="fr">{ $item-fr/Name/text() }</th:Label>
        else
          ()
        }
        {
        if ($item-de) then
          <th:Label Lang="de">{ $item-de/Name/text() }</th:Label>
        else
          ()
        }
      </th:Item>
    }
  </th:List>
};

(: ======================================================================
   Same as local:gen-simple-list-I but in double list context
   ======================================================================
:)
declare function local:gen-simple-list-II( $root as element()?, $root-fr as element()?, $root-de as element()? ) as element()
{
  <th:List>
    {
    for $item in $root/Option

    let $item-fr := $root-fr/Option[Value eq $item/Value]

    let $item-de := $root-de/Option[Value eq $item/Value]

    return
      <th:Item>
        <th:Key>{$item/Value/text()}</th:Key>
        <th:Label Lang="en">{ $item/Name/text() }</th:Label>
        {
        if ($item-fr) then
          <th:Label Lang="fr">{ $item-fr/Name/text() }</th:Label>
        else
          ()
        }
        {
        if ($item-de) then
          <th:Label Lang="de">{ $item-de/Name/text() }</th:Label>
        else
          ()
        }
      </th:Item>
    }
  </th:List>
};

(: ======================================================================
   Transforms a simple list generic representation into an XTiger XML template
   Current list content becomes default content
   ======================================================================
:)
declare function local:gen-template-for-editing( $data as element() ) as element()
{
  <html xmlns="http://www.w3.org/1999/xhtml" xmlns:xt="http://ns.inria.org/xtiger">
    <xt:head version="1.1" templateVersion="1.0" label="SimpleList">
      {
      for $item in $data/th:Item
      return
        <xt:component name="t_item_{$item/th:Key}">
          <tr>
            <td><xt:use types="constant" label="Key">{$item/th:Key/text()}</xt:use></td>
            <td><xt:use types="text" param="type=textarea;shape=parent" label="Label-EN">{ $item/th:Label[@Lang = 'en']/text() }</xt:use></td>
            <td>
            {
            if ($item/th:Label[@Lang = 'fr']) then
              <xt:use types="text"  param="type=textarea;shape=parent" label="Label-FR">{ $item/th:Label[@Lang = 'fr']/text() }</xt:use>
            else
              "---"
            }
            </td>
            <td>
            {
            if ($item/th:Label[@Lang = 'de']) then
              <xt:use types="text"  param="type=textarea;shape=parent" label="Label-DE">{ $item/th:Label[@Lang = 'de']/text() }</xt:use>
            else
              "---"
            }
            </td>
          </tr>
        </xt:component>
      }
    </xt:head>
    <body>
      {
      if (count($data/th:Item) = 0) then
        <p>Pas de données à éditer dans la base de données</p>
      else
        <table class="table table-bordered">
          <thead>
            <tr>
              <th style="width:100px">Clef</th>
              <th>Label (en)</th>
              <th>Label (fr)</th>
              <th>Label (de)</th>
            </tr>
          </thead>
          <tbody>
          {
          for $item in $data/th:Item
          return
            <xt:use types="t_item_{$item/th:Key}" label="Item"/>
          }
          </tbody>
        </table>
      }
    </body>
  </html>
};

(: ======================================================================
   Generates double entry list data model for editing
   FIXME: generate multiple Labels <Label Lang='fr'> and <Label Lang='de'>
   ======================================================================
:)
declare function local:gen-double-list( $root as element()?, $spec as element() ) as element()
{
  <th:List>
    {
    for $item in $root/Group
    let $item-fr := local:get-selector($spec/@Root, 'fr')/Group[Value = $item/Value]
    let $item-de := local:get-selector($spec/@Root, 'de')/Group[Value = $item/Value]
    return
      <th:Item>
        <th:Key>{ $item/Value/text() }</th:Key>
        <th:Label Lang="en">{ $item/Name/text() }</th:Label>
        {
        if ($item-fr) then
          <th:Label Lang="fr">{ $item-fr/Name/text() }</th:Label>
        else
          (),
        if ($item-de) then
          <th:Label Lang="de">{ $item-de/Name/text() }</th:Label>
        else
          (),
        local:gen-simple-list-II($item/Selector, $item-fr/Selector, $item-de/Selector)
        }
      </th:Item>
    }
  </th:List>
};

(: ======================================================================
   Extracts a double list from the database and transforms it into
   a generic representation suitable for transformation to an XTiger template
   FIXME: generate multiple Labels <Label Lang='fr'> and <Label Lang='de'>
   ======================================================================
:)
declare function local:gen-selector-for-editing-II( $id as xs:string, $list-spec as element() ) {
  let $spec := $list-spec/th:List[@id = $id]
  return
    local:gen-double-list(local:get-selector($spec/@Root, 'en'), $spec)
};

(: ======================================================================
   Transforms a double list generic representation into an XTiger XML template
   Current lists content becomes default content
   ======================================================================
:)
declare function local:gen-double-template-for-editing( $data as element() ) as element()
{
  <html xmlns="http://www.w3.org/1999/xhtml" xmlns:xt="http://ns.inria.org/xtiger">
    <xt:head version="1.1" templateVersion="1.0" label="DoubleList">
      {
      for $item in $data/th:Item
      return (
        <xt:component name="t_list_{$item/th:Key}">
          <table class="table table-bordered">
            <thead>
              <tr>
                <th style="width:50px">Clef</th>
                <th style="width:226px">Label (en)</th>
                <th style="width:226px">Label (fr)</th>
                <th style="width:226px">Label (de)</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td><xt:use types="constant" label="Key">{ $item/th:Key/text() }</xt:use></td>
                <td><xt:use types="text" param="type=textarea;shape=parent-20px" label="Label-EN">{$item/th:Label[@Lang = 'en']/text()}</xt:use></td>
                <td>
                {
                if ($item/th:Label[@Lang = 'fr']) then
                  <xt:use types="text" param="type=textarea;shape=parent-20px" label="Label-FR">{ $item/th:Label[@Lang = 'fr']/text() }</xt:use>
                else
                  "---"
                }
                </td>
                <td>
                {
                if ($item/th:Label[@Lang = 'de']) then
                  <xt:use types="text" param="type=textarea;shape=parent-20px" label="Label-DE">{ $item/th:Label[@Lang = 'de']/text() }</xt:use>
                else
                  "---"
                }
                </td>
              </tr>
            </tbody>
          </table>
          <xt:use types="t_content_{$item/th:Key}" label="List"/>
        </xt:component>,
        <xt:component name="t_content_{$item/th:Key}">
          <table class="table table-bordered">
            <tbody>
            {
            for $subitem in $item/th:List/th:Item
            return
                  <xt:use types="t_item_{$item/th:Key}_{$subitem/th:Key}" label="Item"/>
            }
            </tbody>
          </table>
        </xt:component>,
        for $subitem in $item/th:List/th:Item
        return
          <xt:component name="t_item_{$item/th:Key}_{$subitem/th:Key}">
            <tr>
              <td style="width:50px"><xt:use types="constant" label="Key">{ $subitem/th:Key/text() }</xt:use></td>
              <td style="width:226px"><xt:use types="text" param="type=textarea;shape=parent-20px"  label="Label-EN">{ $subitem/th:Label[@Lang = 'en']/text() }</xt:use></td>
              <td style="width:226px">
              {
              if ($item/th:Label[@Lang = 'fr']) then
                <xt:use types="text" param="type=textarea;shape=parent-20px"  label="Label-FR">{ $subitem/th:Label[@Lang = 'de']/text() }</xt:use>
              else
                "---"
              }
              </td>
              <td style="width:226px">
              {
              if ($item/th:Label[@Lang = 'de']) then
                <xt:use types="text" param="type=textarea;shape=parent-20px"  label="Label-DE">{ $subitem/th:Label[@Lang = 'de']/text() }</xt:use>
              else
                "---"
              }
              </td>
            </tr>
          </xt:component>
      )
      }
    </xt:head>
    <body>
      {
      if (count($data/th:Item) = 0) then
        <p>Pas de données à éditer dans la base de données</p>
      else
        for $item in $data/th:Item
        return (
          <xt:use types="t_list_{$item/th:Key}" label="Item"/>,
          <br/>
          )
      }
    </body>
  </html>
};

(: ======================================================================
   Updates a simple list in Global Information in a given lang (Upper case)
   (also used to update simple lists inside double lists)
   ======================================================================
:)
declare function local:update-simple-list(
  $spec as element(),
  $list as element(),
  $data as element(),
  $ulang as xs:string
  )
{
  for $item in $list/Option
  let $key := $item/Value
  let $label := $item/Name
  let $new-label := $data/Item[Key = $key/text()]/*[local-name(.) = concat('Label-', $ulang)]
  where not(empty($new-label)) and ($new-label ne $label)
  return
    update value $item/Name with $new-label/text()
};

(: ======================================================================
   Updates a simple list in Global Information from submitted data
   in a given lang (stub function)
   ======================================================================
:)
declare function local:update-simple-data(
  $id as xs:string,
  $lang as xs:string,
  $data as element()
  )
{
  let $spec := $th:simple-lists/th:List[@id = $id]
  let $ulang := upper-case($lang)
  let $list := local:get-selector($spec/@Root, $lang)
  return
    if ($list) then (
      cache:invalidate(string($spec/@Root), $lang),
      local:update-simple-list($spec, $list, $data, $ulang)
      )
    else
     ()

};

(: ======================================================================
   Updates a double list in Global Information from submitted data in a given lang
   ======================================================================
:)
declare function local:update-double-data(
  $id as xs:string,
  $lang as xs:string,
  $data as element()
  )
{
  let $spec := $th:double-lists/th:List[@id = $id]
  let $ulang := upper-case($lang)
  let $list := local:get-selector($spec/@Root, $lang)
  return
    if ($list) then (
      cache:invalidate(string($spec/@Root), $lang),
      for $item in $list/Option
      let $key := $item/Value
      let $label := $item/Name
      let $new-label := $data/Item[Key = $key/text()]/*[local-name(.) = concat('Label-', $ulang)]
      return (
        if (not(empty($new-label)) and ($new-label ne $label)) then
          update value $item/Name with $new-label/text()
        else
          (),
        local:update-simple-list($spec/th:List,
          $item/*[local-name(.) = string($spec/th:List/@Root)],
          $data/Item[Key = $key/text()]/List,
          $ulang)
        )
      )
    else
      ()
};

let $m := request:get-method()
let $id := request:get-parameter('id', ())
return
  if ($m = 'POST') then
    let $data := oppidum:get-data()
    return (
        if (local-name($data) = 'SimpleList') then (
          if (count($data//Label-FR) > 0) then local:update-simple-data($id, 'fr', $data) else (),
          if (count($data//Label-DE) > 0) then local:update-simple-data($id, 'de', $data) else (),
          if (count($data//Label-EN) > 0) then local:update-simple-data($id, 'en', $data) else ()
          )
        else ( (: assumes 'DoubleList' :)
          if (count($data//Label-FR) > 0) then local:update-double-data($id, 'fr', $data) else (),
          if (count($data//Label-DE) > 0) then local:update-double-data($id, 'de', $data) else (),
          if (count($data//Label-FR) > 0) then local:update-double-data($id, 'en', $data) else ()
          ),
      ajax:report-success('ACTION-UPDATE-SUCCESS', ())
      )[last()]
  else (: assumes GET :)
    let $template := request:get-parameter('template', ())
    return
      if ($template eq '1') then (: XTiger template generation for modal window :)
        local:gen-template-for-editing(
          local:gen-selector-for-editing-I($id, $th:simple-lists)
        )
      else if ($template eq '2') then (: XTiger template generation for modal window :)
        local:gen-double-template-for-editing(
          local:gen-selector-for-editing-II($id, $th:double-lists)
        )
      else (: List selection menu generation for tab pane :)
        <div id="results" class="row-fluid">
          <h2>Thesaurus</h2>
          <p>Cliquez sur un nom de liste pour modifier les options associées.</p>
          <div class="span5">
            <ul class="unstyled">
              {
              for $l in $th:simple-lists/th:List
              return
                <li><a href="#" data-controller="management/thesaurus?id={$l/@id}&amp;template=1">{string($l/@Root)}</a></li>
              }
            </ul>
          </div>
          <div class="span5">
            <ul class="unstyled">
            {
            for $l in $th:double-lists/th:List
            return
              <li><a href="#" data-controller="management/thesaurus?id={$l/@id}&amp;template=2">{string($l/@Root)}</a></li>
            }
            </ul>
          </div>
          <div class="span10" style="margin-left:0">
            <p>Les entrées marquées --- dans les listes ne sont pas définies, il faut qu'un administrateur de la base de donnée les crée d'abord dans la ressource <tt>global-information.xml</tt>.</p>
          </div>
        </div>
