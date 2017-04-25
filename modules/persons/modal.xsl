<?xml version="1.0" encoding="UTF-8"?>
<!--
     Case tracker pilote

     Creator: Stéphane Sire <s.sire@opppidoc.fr>

     November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
  -->
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:site="http://oppidoc.com/oppidum/site"
  xmlns="http://www.w3.org/1999/xhtml">

  <xsl:output method="xml" media-type="text/html" omit-xml-declaration="yes" indent="yes"/>

  <xsl:template match="Person">
    <div>
      <p><xsl:apply-templates select="Name"/></p>
      <xsl:apply-templates select="Photo[.!='']"/>
      <p>
        <span loc="term.enterprise">Enterprise</span>: 
        <xsl:call-template name="pretty-print">
          <xsl:with-param name="var"><xsl:value-of select="EnterpriseName"/></xsl:with-param>
        </xsl:call-template>
      </p>
      <xsl:apply-templates select="Contacts/Email"/>
      <p>
        <span loc="term.mobile">Mobile</span>: 
        <xsl:call-template name="pretty-print">
          <xsl:with-param name="var"><xsl:value-of select="Contacts/Mobile"/></xsl:with-param>
        </xsl:call-template>
      </p>
      <p>
        <span loc="term.phoneAbbrev">Phone</span>: 
        <xsl:call-template name="pretty-print">
          <xsl:with-param name="var"><xsl:value-of select="Contacts/Phone"/></xsl:with-param>
        </xsl:call-template>
      </p>
      <xsl:apply-templates select="Roles"/>
    </div>
  </xsl:template>

  <xsl:template match="Name">
    <xsl:value-of select="FirstName"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="LastName"/>
  </xsl:template>

  <xsl:template match="Email">  
    <p>
      <a href="mailto:{.}"><xsl:value-of select="."/></a>
    </p>
  </xsl:template>

  <xsl:template match="Email[. = '']">
    <p>Unkown E-mail</p>
  </xsl:template>
  
  <xsl:template match="Photo">
    <img src="persons/{.}" style="float:right;max-width:200px"/>
  </xsl:template>

  <xsl:template match="Roles">
    <xsl:apply-templates select="Function"/>
  </xsl:template>
  
  <xsl:template match="Function">
    <xsl:value-of select="."/><xsl:apply-templates select="./following-sibling::Name[1]" mode="function"/><xsl:text>, </xsl:text>
  </xsl:template>

  <xsl:template match="Function[count(./following-sibling::Function) = 0]">
    <xsl:value-of select="."/><xsl:apply-templates select="./following-sibling::Name[1]" mode="function"/>
  </xsl:template>
  
  <xsl:template match="Name[.!='']" mode="function"> for <xsl:value-of select="."/>
  </xsl:template>

  <xsl:template name="pretty-print">
    <xsl:param name="var"/>
    <xsl:choose>
      <xsl:when test="$var != ''"><xsl:value-of select="$var"/></xsl:when>
      <xsl:otherwise>not known</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- DEPRECATED ? -->
  <xsl:template match="ServiceResponsible">
    <p>
      <xsl:value-of select="FunctionName"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="ServiceName"/>
    </p>    
  </xsl:template>
  
  <!-- DEPRECATED ? -->
  <xsl:template match="Coach">
    <p>
      <xsl:value-of select="FunctionName"/>
      <xsl:text> </xsl:text>
      <xsl:apply-templates select="Services"/>
    </p>
  </xsl:template>
  
  <!-- DEPRECATED ? -->
  <xsl:template match="CantonalAntennaResponsible">
    <p>
      <xsl:value-of select="FunctionName"/>
      <xsl:text> </xsl:text>
      <xsl:apply-templates select="CantonalAntenna"/>
    </p>
  </xsl:template>
  
</xsl:stylesheet>
