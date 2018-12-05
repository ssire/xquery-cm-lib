<?xml version="1.0" encoding="UTF-8"?>
<!-- 
     Case tracker pilote

     Author: Stéphane Sire <s.sire@opppidoc.fr>

     Enterprise search page generation

     DEPRECATED: move to enterprise.xsl in your application project depot

     November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
  -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:site="http://oppidoc.com/oppidum/site" xmlns="http://www.w3.org/1999/xhtml">

  <xsl:output method="xml" media-type="text/html" omit-xml-declaration="yes" indent="yes"/>

  <xsl:param name="xslt.base-url">/</xsl:param>

  <xsl:include href="../../lib/commons.xsl"/>
  <xsl:include href="../../lib/widgets.xsl"/>
  <xsl:include href="../../lib/search.xsl"/>

  <xsl:template match="/Search">
    <div id="results">
      <xsl:apply-templates
        select="/Search/NoRequest | /Search/Results/Enterprises |  /Search/Results/Empty "/>
    </div>
  </xsl:template>

  <xsl:template match="/Search[@Initial='true']" priority="1">
    <site:view skin="search">
      <site:window><title loc="form.title.enterprise.search">Title</title></site:window>
      <site:title>
        <h1 loc="form.title.enterprise.search">Title</h1>
      </site:title>
      <site:content>
        <xsl:apply-templates select="Formular"/>
        <div class="row">
          <div class="span12">
            <p id="c-busy" style="display: none; color: #999;margin-left:380px;height:32px">
              <span loc="term.loading" style="margin-left: 50px;vertical-align:middle">Recherche en cours...</span>
            </p>
            <div id="results">
              <xsl:apply-templates
                select="/Search/NoRequest | /Search/Results/Enterprises | /Search/Results/Empty "/>
            </div>
          </div>
        </div>
        <xsl:apply-templates select="/Search/Modals/Modal"/>
      </site:content>
    </site:view>
  </xsl:template>

  <xsl:template match="Enterprises[not(Enterprise)]">
    <h2 loc="app.title.noResults">Pas de résultats</h2>
    <p loc="app.message.noResults">Aucune entreprise ne correspond à ces critères</p>
  </xsl:template>

  <xsl:template match="Enterprises[Enterprise]">
    <!-- <xsl:apply-templates select="../@Duration"/> -->
    <h2><span loc="enterprise.search.result.message1">Résultats</span> – <xsl:value-of
        select="count(Enterprise)"/><xsl:text> </xsl:text>
      <span loc="enterprise.search.result.message2">entreprise(s)</span></h2>
    <table class="table table-bordered">
      <thead>
        <tr>
          <th loc="term.name">Nom</th>
          <th loc="term.town">Localité</th>
          <th loc="term.country">Country</th>
          <th loc="term.enterpriseSize">Taille</th>
          <th loc="term.domainActivity">NACE</th>
          <th loc="term.targetedMarkets">Marchés ciblés</th>
          <th loc="term.persons">Personnes</th>
        </tr>
      </thead>
      <tbody localized="1">
        <xsl:apply-templates select="Enterprise"/>
      </tbody>
    </table>
  </xsl:template>

  <xsl:template match="@Duration">
    <p style="float:right; color: #004563;">(requête traitée en <xsl:value-of select="."/> s)</p>
  </xsl:template>

  <xsl:template match="Enterprise">
    <tr data-id="{Id}">
      <td>
        <xsl:apply-templates select="Name"/>
      </td>
      <td>
        <xsl:apply-templates select="Address/Town"/>
      </td>
      <td>
        <xsl:value-of select="Address/Country"/>
      </td>
      <td>
        <xsl:value-of select="Size"/>
      </td>
      <td>
        <xsl:value-of select="DomainActivity"/>
      </td>
      <td>
        <xsl:value-of select="TargetedMarkets"/>
      </td>
      <td>
        <xsl:value-of select="Persons"/>
      </td>
    </tr>
  </xsl:template>

  <xsl:template match="Name">
    <xsl:variable name="update"><xsl:if test="ancestor::*[@Update = 'y']">!</xsl:if></xsl:variable>
    <a>
      <span data-src="{$update}enterprises/{../Id}">
        <xsl:value-of select="."/>
      </span>
    </a>
  </xsl:template>

</xsl:stylesheet>
