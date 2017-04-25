xquery version "1.0";
(: --------------------------------------
   XQuery Content Management Library

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Sample service to return options to dynamically load into a 'choice' plugin
   using an 'ajax' binding

   February 2017 - (c) Copyright 2017 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

declare namespace json="http://www.json.org";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../oppidum/lib/util.xqm";

declare option exist:serialize "method=json media-type=application/json";

(: JSON protocol requires that items property contains an array
   do not forget to add a json:array="true" on items if it is unique 
:)
let $contacts := 
  <samples>
    <sample cache="1">
      <items>
        { attribute { 'json:array' } { 'true' } }
        <label>Minny</label>
        <value>1</value>
      </items>
      <items>
        <label>Steve</label>
        <value>2</value>
      </items>
    </sample>
    <sample cache="2">
      <items>
        <label>John</label>
        <value>3</value>
      </items>
      <items>
        <label>Paul</label>
        <value>4</value>
      </items>  
      <items>
        <label>Saul</label>
        <value>5</value>
      </items>
    </sample>
    <sample cache="3">
      <items>
        <label>Raul</label>
        <value>6</value>
      </items>
      <items>
        <label>Bill</label>
        <value>7</value>
      </items>
      <items>
        <label>Melinda</label>
        <value>8</value>
      </items>
    </sample>
  </samples>
let $contracts := 
  <samples>
    <sample cache="1">
      <items>
        { attribute { 'json:array' } { 'true' } }
        <label>ABC</label>
        <value>A</value>
      </items>
      <items>
        <label>DEF</label>
        <value>D</value>
      </items>
    </sample>
    <sample cache="2">
      <items>
        <label>HIJ</label>
        <value>H</value>
      </items>
      <items>
        <label>KLM</label>
        <value>K</value>
      </items>  
      <items>
        <label>OPQ</label>
        <value>O</value>
      </items>
    </sample>
    <sample cache="3">
      <items>
        <label>RST</label>
        <value>R</value>
      </items>
      <items>
        <label>TUV</label>
        <value>T</value>
      </items>
      <items>
        <label>WXY</label>
        <value>W</value>
      </items>
    </sample>
  </samples>
return  
  if (oppidum:get-command()/resource/@name eq 'contacts') then
    let $company := request:get-parameter('company', ())
    return $contacts/sample[@cache eq $company]
  else
    let $contact := request:get-parameter('contact', ())
    return (: random :)
      <sample cache="{ $contact }">
        {
        for $i in 1 to util:random(9) + 1
        return
          <items>
            <label>
              { 
              codepoints-to-string(
                for $i in 1 to util:random(7) + 3
                return 65 + util:random(25)
              )
              }
            </label>
            <value>{ $i }</value>
          </items>
        }
      </sample>

