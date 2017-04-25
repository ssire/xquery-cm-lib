<?xml version="1.0" encoding="UTF-8"?>
<!-- Case tracker pilote

     Author: Stéphane Sire <s.sire@opppidoc.fr>

     November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
  -->
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:site="http://oppidoc.com/oppidum/site"
  xmlns="http://www.w3.org/1999/xhtml">

  <xsl:output method="xml" media-type="text/html" omit-xml-declaration="yes" indent="yes"/>

  <xsl:template match="/Enterprise">
    <div>
      <p><xsl:value-of select="Name"/></p>
      <xsl:apply-templates select="WebSite"/>
      <p><xsl:value-of select="SizeRef/@_Display"/></p>
      <p><xsl:value-of select="DomainActivityRef/@_Display"/></p>
      <xsl:apply-templates select="Address"/>
      <xsl:apply-templates select="CreationYear[. != '']"/>
    </div>
  </xsl:template>

  <xsl:template match="Address">
    <address>
      <xsl:apply-templates select="StreetNameAndNo[.!=''] | Town[.!=''] | PostalCode[.!=''] | State[.!=''] | Country[.!='']"/>
    </address>
  </xsl:template>

  <xsl:template match="StreetNameAndNo | Town | PostalCode | State"><xsl:value-of select="."/><br/></xsl:template>

  <xsl:template match="Country"><xsl:value-of select="@_Display"/></xsl:template>

  <xsl:template match="CreationYear">
    <p>Established in <xsl:value-of select="."/></p>
  </xsl:template>

  <xsl:template match="WebSite">
    <p>
      <a target="_blank">
        <xsl:attribute name="href">
          <xsl:choose>
            <xsl:when test="starts-with(., 'http://') or starts-with(., 'https://')"><xsl:value-of select="."/></xsl:when>
            <xsl:otherwise><xsl:value-of select="concat('http://', .)"/></xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
        <xsl:value-of select="."/>
      </a>
    </p>
  </xsl:template>
</xsl:stylesheet>
