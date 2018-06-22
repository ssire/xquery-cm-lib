<?xml version="1.0" encoding="UTF-8"?>
<!--
     XQuery Content Management Library

     Author: Stéphane Sire <s.sire@opppidoc.fr>

     Common widget vocabulary for generic platform level user interface

     Last update: 2016-11-25

     November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
  -->
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:site="http://oppidoc.com/oppidum/site"
  xmlns="http://www.w3.org/1999/xhtml">

  <xsl:variable name="smallcase" select="'abcdefghijklmnopqrstuvwxyz'" />
  <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />

  <!-- ************************ -->
  <!--  Ajax response protocol  -->
  <!-- ************************ -->
  
  <xsl:template match="success">
    <success>
      <xsl:copy-of select="message"/>
      <xsl:apply-templates select="payload"/>
      <xsl:copy-of select="forward"/>
    </success>
  </xsl:template>

  <!-- Ajax response with payload go through XSLT transformation to generate HTML fragments  -->
  <xsl:template match="payload">
    <payload>
      <xsl:apply-templates select="*"/>
    </payload>
  </xsl:template>

  <!-- *********************************************** -->
  <!--  Common micro-format and attributes generators  -->
  <!-- *********************************************** -->

  <xsl:template match="@Id">
    <xsl:attribute name="id"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <xsl:template match="@Target">
    <xsl:attribute name="data-target"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>
  
  <xsl:template match="@EventTarget">
    <xsl:attribute name="data-event-target"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <xsl:template match="@Command">
    <xsl:attribute name="data-command"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <!-- Confirmation popup dialog -->
  <xsl:template match="Confirm">
    <xsl:attribute name="data-confirm"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <!-- ************************************ -->
  <!--  <Label> for localization of parent  -->
  <!-- ************************************ -->

  <xsl:template match="Label">
    <xsl:copy-of select="@loc | @style"/>
    <xsl:value-of select="."/>
  </xsl:template>

  <!-- ****************************************** -->
  <!--                 TOP LEVEL                  -->
  <!-- ****************************************** -->
  
  <!-- FIXME: merge with Display top level widget ? -->
  <xsl:template match="Page">
    <site:view>
      <xsl:copy-of select="@skin"/>
      <xsl:apply-templates select="*"/>
    </site:view>
  </xsl:template>

  <!-- ****************************************** -->
  <!--                PAGE CONTENT                -->
  <!-- ****************************************** -->
  
  <xsl:template match="Window">
    <site:window>
      <title><xsl:copy-of select="@loc"/><xsl:value-of select="."/></title>
    </site:window>
  </xsl:template>

  <xsl:template match="Content">
    <site:content>
      <title><xsl:copy-of select="@loc"/><xsl:value-of select="."/></title>
      <xsl:apply-templates select="*"/>
    </site:content>
  </xsl:template>

  <xsl:template match="Overlay">
    <site:overlay>
      <xsl:apply-templates select="*"/>
    </site:overlay>
  </xsl:template>

  <xsl:template match="Views">
    <xsl:apply-templates select="@* | *"/>
  </xsl:template>

  <xsl:template match="View">
    <div>
      <xsl:apply-templates select="@* | *"/>
    </div>
  </xsl:template>

  <!-- ****************************************** -->
  <!--             STANDARD COMPONENTS            -->
  <!-- ****************************************** -->

  <xsl:template match="Title[@Level]">
    <xsl:element name="h{@Level}">
      <xsl:copy-of select="@loc|@style"/>
      <xsl:apply-templates select="@Offset"/>
      <xsl:apply-templates select="* | text()"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="Title[not(@Level)]">
    <xsl:element name="h1">
      <xsl:copy-of select="@loc|@style"/>
      <xsl:apply-templates select="@Offset"/>
      <xsl:apply-templates select="* | text()"/>
    </xsl:element>
  </xsl:template>

  <!-- ****************************************** -->
  <!--              OTHER MECHANISMS              -->
  <!-- ****************************************** -->

  <!-- Generic mechanism for intra-page Models inclusion
       FIXME: hard-coded to work only with Display top level -->
  <xsl:template match="Insert">
    <xsl:variable name="target"><xsl:value-of select="@Match"/></xsl:variable>
    <xsl:apply-templates select="/Display/Models/Instance[@Name = $target]/*"/>
  </xsl:template>

</xsl:stylesheet>
