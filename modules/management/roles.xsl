<?xml version="1.0" encoding="UTF-8"?>
<!--
     Case tracker pilote

     Creator: Stéphane Sire <s.sire@opppidoc.fr>

     November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
  -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:site="http://oppidoc.com/oppidum/site" xmlns="http://www.w3.org/1999/xhtml">

  <xsl:output method="xml" media-type="text/html" omit-xml-declaration="yes" indent="yes"/>

  <xsl:param name="xslt.base-url">/</xsl:param>

  <xsl:template match="/Roles[not(Role)]">
    <div id="results">
      <p>No role defined in database global configuration</p>
    </div>
  </xsl:template>

  <xsl:template match="/Roles">
    <div id="results">
      <h2>Users by role</h2>
      <xsl:apply-templates select="Role"/>
    </div>
  </xsl:template>
  
  <xsl:template match="Role">
    <h3><xsl:value-of select="@Name"/></h3>
    <p><xsl:value-of select="."/></p>
  </xsl:template>
</xsl:stylesheet>
