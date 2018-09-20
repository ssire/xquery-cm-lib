<?xml version="1.0" encoding="UTF-8"?>
<!--
     Case tracker pilote

     Creator: Stéphane Sire <s.sire@opppidoc.fr>

     DEPRECATED: moved to persons.xsl in the persons module in your application

     Shared XSL templates to generate a search person page

     January 2015 - (c) Copyright 2015 Oppidoc SARL. All Rights Reserved.
  -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:site="http://oppidoc.com/oppidum/site" xmlns="http://www.w3.org/1999/xhtml">

  <xsl:output method="xml" media-type="text/html" omit-xml-declaration="yes" indent="yes"/>

  <xsl:param name="xslt.base-url">/</xsl:param>

  <!-- =========== -->
  <!-- EXTENSIONS  -->
  <!-- =========== -->
  <xsl:include href="../../lib/commons.xsl"/>
  <xsl:include href="../../lib/widgets.xsl"/>
  <xsl:include href="../../lib/search.xsl"/>
  <xsl:include href="person.xsl"/>

  <!-- Search results set in a fragment (Ajax) -->
  <xsl:template match="/Search">
    <div id="results">
      <xsl:apply-templates select="/Search/NoRequest | /Search/Results/Empty | /Search/Results/Persons | /Search/Results/Coaches "/>
    </div>
  </xsl:template>

  <!-- Search initial User Interface  -->
  <xsl:template match="/Search[@Initial='true']" priority="1">
    <site:view skin="{@skin}">
      <site:window><title loc="{Formular/Template/@loc}">Title</title></site:window>
      <site:title>
        <h1 loc="{Formular/Template/@loc}">Title</h1>
      </site:title>
      <site:content>
        <xsl:apply-templates select="Formular"/>
        <div class="row">
          <div class="span12">
            <p id="c-busy" style="display: none; color: #999;margin-left:380px;height:32px">
              <span loc="term.loading" style="margin-left: 50px;vertical-align:middle">Recherche en cours...</span>
            </p>
            <div id="results">
              <xsl:apply-templates select="/Search/*[local-name(.) != 'Formular' and local-name(.) != 'Modals' and local-name(.) != 'Overlay']"/>
            </div>
          </div>
        </div>
        <xsl:apply-templates select="/Search/Modals/Modal"/>
      </site:content>
      <xsl:apply-templates select="/Search/Overlay"/>
    </site:view>
  </xsl:template>

  <xsl:template match="Persons[not(Person)]">
    <h2 loc="app.title.noResults">Pas de résultats</h2>
    <p loc="app.message.noResults">Il n'y a pas de résultats pour les critères sélectionnés.</p>
  </xsl:template>

  <!-- Generic persons search page -->
  <xsl:template match="Persons">
    <h2><span loc="person.search.result.message1">Résultats</span> – <xsl:value-of select="count(Person/Id)"/><xsl:text> </xsl:text><span loc="person.search.result.message2">personne(s)</span></h2>

    <table class="table table-bordered">
      <thead>
        <tr>
          <th loc="term.name">Nom</th>
          <th loc="term.country" style="min-width:7em">Pays</th>
          <th loc="term.email">Email</th>
          <th loc="term.mobile" class="mobile">Mobile</th>
          <th loc="term.phone" class="phone">Téléphone</th>
          <th loc="term.enterprise">Entreprise</th>
        </tr>
      </thead>
      <tbody localized="1">
        <xsl:apply-templates select="Person">
          <xsl:sort select="Name/LastName" order="ascending"/>
        </xsl:apply-templates>
      </tbody>
    </table>
  </xsl:template>

  <xsl:template match="*|@*|text()">
    <xsl:copy>
      <xsl:apply-templates select="*|@*|text()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
