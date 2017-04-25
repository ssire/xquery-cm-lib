<?xml version="1.0" encoding="UTF-8"?>
<!-- 
     Case tracker pilote

     Author: Stéphane Sire <s.sire@opppidoc.fr>

     Login history view

     November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
  -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:site="http://oppidoc.com/oppidum/site" xmlns="http://www.w3.org/1999/xhtml">

  <xsl:output method="xml" media-type="text/html" omit-xml-declaration="yes" indent="yes"/>

  <xsl:param name="xslt.base-url">/</xsl:param>

  <!-- Optional unique login count when different  -->
  <xsl:template match="@UniCount"> / <xsl:value-of select="."/></xsl:template>
  <xsl:template match="@UniCount[count(parent::*/Login) = .]"></xsl:template>

  <xsl:template match="/Logs[not(Login) and not(Hold)]">
    <div id="results">
      <p>Nobody</p>
      <xsl:apply-templates select="." mode="shutdown"/>
    </div>
  </xsl:template>

  <xsl:template match="/Logs">
    <div id="results">
      <xsl:apply-templates select="." mode="shutdown"/>
      <h2>Today's login <span style="font-size:75%">(<xsl:value-of select="count(Today/Login)"/><xsl:apply-templates select="Today/@UniCount"/>)</span></h2>
      <p>Current time <b><xsl:value-of select="@Time"/></b></p>
      <xsl:apply-templates select="Today | Yesterday"/>
    </div>
  </xsl:template>

  <xsl:template match="Logs" mode="shutdown">
    <p>No shutdown window defined</p>
  </xsl:template>

  <xsl:template match="Logs[@Shutdown]" mode="shutdown">
    <p>A shutdown window is defined starting at <xsl:value-of select="@Shutdown"/> for a duration of <xsl:value-of select="@Duration"/></p>
  </xsl:template>

  <xsl:template match="Today">
    <xsl:apply-templates select="Login | Hold | Logout"/>
  </xsl:template>

  <xsl:template match="Yesterday">
    <h2>Yesterday's login <span style="font-size:75%">(<xsl:value-of select="count(Login)"/><xsl:apply-templates select="@UniCount"/>)</span></h2>
    <xsl:apply-templates select="Login | Hold | Logout"/>
  </xsl:template>

  <xsl:template match="Yesterday[not(Login) and not(Hold)]">
    <h2>Yesterday's login</h2>
    <p><i>none</i></p>
  </xsl:template>

  <!-- ie -->
  <xsl:template match="Login">
    <p><xsl:value-of select="@User"/> at <xsl:value-of select="substring(@TS, 12, 5)"/> blocked (<xsl:value-of select="."/>)<xsl:apply-templates select="@UA"/></p>
  </xsl:template>

  <xsl:template match="Login[. = 'success']">
    <p><xsl:value-of select="@User"/> at <xsl:value-of select="substring(@TS, 12, 5)"/><xsl:apply-templates select="@UA"/></p>
  </xsl:template>

  <xsl:template match="@UA"></xsl:template>

  <xsl:template match="@UA[/Logs/@Full = 'on']"><xsl:text> </xsl:text>[<xsl:value-of select="."/>]
  </xsl:template>

  <xsl:template match="Hold">
    <p><xsl:value-of select="@User"/> at <xsl:value-of select="substring(@TS, 12, 5)"/> set maintenance <xsl:value-of select="."/></p>
  </xsl:template>

  <xsl:template match="Logout">
    <p><xsl:value-of select="@User"/> at <xsl:value-of select="substring(@TS, 12, 5)"/><xsl:text> </xsl:text><xsl:value-of select="."/> logout</p>
  </xsl:template>
</xsl:stylesheet>
