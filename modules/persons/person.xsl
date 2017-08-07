<?xml version="1.0" encoding="UTF-8"?>
<!--
     Case tracker pilote

     Creator: Stéphane Sire <s.sire@opppidoc.fr>

     XSL templates to generate Person table row in search results list

     January 2015 - (c) Copyright 2015 Oppidoc SARL. All Rights Reserved.
  -->
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml">

  <!-- Generic person search result -->
  <xsl:template match="Person">
    <tr class="unstyled" data-id="{Id}">
      <td>
        <xsl:apply-templates select="Name"/>
      </td>
      <td>
        <xsl:apply-templates select="Country"/>
      </td>      
      <td>
        <xsl:apply-templates select="Contacts/Email"/>
      </td>
      <td>
        <xsl:apply-templates select="Contacts/Mobile"/>
      </td>
      <td>
        <xsl:apply-templates select="Contacts/Phone"/>
      </td>
      <td>
        <xsl:apply-templates select="EnterpriseKey"/>
      </td>
    </tr>
  </xsl:template>

  <xsl:template match="Name">
    <xsl:variable name="update"><xsl:if test="ancestor::*[@Update = 'y']">!</xsl:if></xsl:variable>
    <a>
      <span data-src="{$update}{/Search/@Base}persons/{../Id}">
        <xsl:value-of select="LastName/text()"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="FirstName/text()"/>
      </span>
    </a>
  </xsl:template>

  <xsl:template match="Country">
    <xsl:value-of select="."/>
  </xsl:template>

  <xsl:template match="Country[. = 'C']"><i>coaching</i>
  </xsl:template>

  <xsl:template match="Country[. = 'E']"><i>EEN</i>
  </xsl:template>

  <xsl:template match="EnterpriseKey">
    <xsl:value-of select="@_Display"/>
  </xsl:template>

  <xsl:template match="Email">
    <xsl:element name="a">
      <xsl:attribute name="href">
        <xsl:value-of select="concat('mailto:',.)"/>
      </xsl:attribute>
      <xsl:value-of select="."/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="Mobile">
    <xsl:value-of select="."/>
  </xsl:template>

  <xsl:template match="Phone">
    <xsl:value-of select="."/>
  </xsl:template>

  <xsl:template match="Photo">
    <img src="persons/{.}" style="float:right"/>
  </xsl:template>
  
  <!-- Specific coach search result -->
  <xsl:template match="Service">
    <xsl:variable name="update"><xsl:if test="@Update = 'y'">!</xsl:if></xsl:variable>
    <tr class="unstyled" data-id="{Id}">
      <td>
        <a><span data-src="{$update}services/{Id}"><xsl:value-of select="Name"/></span></a>
      </td>
      <td>
        All
      </td>
      <td>
        <xsl:apply-templates select="Coach"/>
      </td>
    </tr>
  </xsl:template>

  <!-- Specific coach search result -->
  <xsl:template match="Service[Country]">
    <xsl:variable name="update"><xsl:if test="@Update = 'y'">!</xsl:if></xsl:variable>
    <tr class="unstyled" data-id="{Id}">
      <td rowspan="{count(Country)}">
        <a><span data-src="{$update}services/{Id}"><xsl:value-of select="Name"/></span></a>
      </td>
      <td>
        <xsl:value-of select="Country[1]/@Name"/>
      </td>
      <td>
        <xsl:apply-templates select="Country[1]/Coach"/>
      </td>
    </tr>
    <xsl:for-each select="Country[position() > 1]">
      <tr>
        <td>
          <xsl:value-of select="@Name"/>
        </td>
        <td>
          <xsl:apply-templates select="Coach"/>
        </td>
      </tr>
    </xsl:for-each>
  </xsl:template>

  <!-- Specific coach search result -->
  <xsl:template match="Service[ancestor::Results[@Services = 'hideIfEmpty'] and not(.//Coach)]">
  </xsl:template>

  <xsl:template match="Coach">
    <a data-toggle="modal" href="{/Search/@Base}persons/{.}.modal" data-target="#person-modal"><xsl:value-of select="@_Display"/></a><xsl:text>, </xsl:text>
  </xsl:template>

  <xsl:template match="Coach[position() = last()]">
    <a data-toggle="modal" href="{/Search/@Base}persons/{.}.modal" data-target="#person-modal"><xsl:value-of select="@_Display"/></a>
  </xsl:template>  

</xsl:stylesheet>
