xquery version "1.0";
(: --------------------------------------
   Case tracker pilote

   Authors: Stéphane Sire <s.sire@opppidoc.fr>

   Shared database requests for enterprise search

   NOTES
   - most of the request time (maybe 90%) is spent in constructing the list of Persons attached to an Enterprise

   December 2014 - (c) Copyright 2014 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

module namespace search = "http://oppidoc.com/ns/xcm/search";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../../lib/globals.xqm";
import module namespace access = "http://oppidoc.com/ns/xcm/access" at "../../lib/access.xqm";
import module namespace display = "http://oppidoc.com/ns/xcm/display" at "../../lib/display.xqm";

(: ======================================================================
   Generates Enterprise information fields to display in result table
   ======================================================================
:)
declare function local:gen-enterprise-sample ( $e as element(), $lang as xs:string ) as element() {
  <Enterprise>
    { ($e/Id, $e/Name) }
    <DomainActivity>{ display:gen-name-for('DomainActivities', $e/DomainActivityRef, 'en') }</DomainActivity>
    <Address>{ ($e/Address/Town, $e/Address/Country) }</Address>
    <Size>{ display:gen-name-for('Sizes', $e/SizeRef, 'en') }</Size>
    <TargetedMarkets>{ display:gen-name-for('TargetedMarkets', $e/TargetedMarkets/TargetedMarketRef, 'en') }</TargetedMarkets>
    <Persons>
      {
      string-join(for $p in globals:collection('persons-uri')//Person[EnterpriseRef eq $e/Id/text()]
                  return concat($p/Name/FirstName/text(), ' ', $p/Name/LastName/text()),
                  ', ')
      }
    </Persons>
  </Enterprise>
};

(: ======================================================================
   Returns Enterprise(s) matching request with request timing
   ======================================================================
:)
declare function search:fetch-enterprises ( $request as element() ) as element() {
  let $omni := access:check-user-can('update', 'Enterprise')
  return
    <Results>
      <Enterprises>
        {
        if ($omni) then attribute { 'Update' } { 'y' } else (),
        if (count($request/*/*) = 0) then (: empty request :)
          local:fetch-all-enterprises()
        else
          local:fetch-some-enterprises($request)
        }
      </Enterprises>
    </Results>
};

(: ======================================================================
   Dumps all enterprises in database
   ======================================================================
:)
declare function local:fetch-all-enterprises () as element()* 
{
  for $e in globals:doc('enterprises-uri')/Enterprises/Enterprise[not(@EnterpriseId)]
  order by $e/Name
  return
    local:gen-enterprise-sample($e, 'en')
};

(: ======================================================================
   Dumps a subset of enterprise filtered by criterias
   ======================================================================
:)
declare function local:fetch-some-enterprises ( $filter as element() ) as element()*
{
  let $enterprise := $filter//EnterpriseRef/text()
  let $town := $filter//Town/text()
  let $country := $filter//Country/text()
  let $size := $filter//SizeRef/text()
  let $domain := $filter//DomainActivityRef/text()
  let $market := $filter//TargetedMarketRef/text()
  let $person := $filter//Person/text()
  return
    for $e in globals:doc('enterprises-uri')//Enterprise[not(@EnterpriseId)]
    where (empty($enterprise) or $e/Id = $enterprise)
      and (empty($town) or $e/Address/Town/text() = $town)
      and (empty($country) or $e/Address/Country/text() = $country)
      and (empty($size) or $e/SizeRef = $size)
      and (empty($domain) or $e/DomainActivityRef = $domain)
      and (empty($market) or $e/TargetedMarkets/TargetedMarketRef = $market)
      and (empty($person) or globals:collection('persons-uri')//Person[(Id = $person) and (EnterpriseRef eq $e/Id/text())])
    order by $e/Name
    return
      local:gen-enterprise-sample($e, 'en')
};
