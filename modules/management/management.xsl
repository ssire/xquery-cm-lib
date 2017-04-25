<?xml version="1.0" encoding="UTF-8"?>
<!--
     Case tracker pilote

     Author: Stéphane Sire <s.sire@opppidoc.fr>

     November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
  -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:site="http://oppidoc.com/oppidum/site" xmlns="http://www.w3.org/1999/xhtml">

  <xsl:output method="xml" media-type="text/html" omit-xml-declaration="yes" indent="yes"/>

  <xsl:param name="xslt.base-url">/</xsl:param>

  <xsl:include href="../../lib/commons.xsl"/>
  <xsl:include href="../../lib/widgets.xsl"/>

  <xsl:template match="Content">
    <site:content>
      <div class="row">
        <div class="span12">
          <xsl:apply-templates select="Tabs"/>
        </div>
      </div>
      <xsl:apply-templates select="Modals"/>
    </site:content>
  </xsl:template>

  <xsl:template match="*|@*|text()">
    <xsl:copy>
      <xsl:apply-templates select="*|@*|text()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
