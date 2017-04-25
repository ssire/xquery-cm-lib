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

  <!-- Optional unique login count when different  -->
  <xsl:template match="@UniCount"> / <xsl:value-of select="."/></xsl:template>
  <xsl:template match="@UniCount[count(parent::*/Login) = .]"></xsl:template>
  <xsl:key name="tod" match="Today/Login" use="substring(@TS,12,2)" />
  <xsl:key name="tods" match="Today/Login[text() = 'success']" use="substring(@TS,12,2)" />
  <xsl:key name="todf" match="Today/Login[text() = 'failure']" use="substring(@TS,12,2)" />
  <xsl:key name="yes" match="Yesterday/Login" use="substring(@TS,12,2)" />
  <xsl:key name="yess" match="Yesterday/Login[text() = 'success']" use="substring(@TS,12,2)" />
  <xsl:key name="yesf" match="Yesterday/Login[text() = 'failure']" use="substring(@TS,12,2)" />
  <xsl:key name="all" match="All/Login" use="substring(@TS,12,2)" />
  <xsl:key name="alls" match="All/Login[text() = 'success']" use="substring(@TS,12,2)" />
  <xsl:key name="allf" match="All/Login[text() = 'failure']" use="substring(@TS,12,2)" />
  
  <xsl:template match="Logs">
    <h2>
      Today's connection rates per hour <span style="font-size:75%">(<xsl:value-of select="count(Today/Login[text() = 'success'])"/>/<xsl:value-of select="count(Today/Login[text() = 'failure'])"/>)</span>
    </h2>
    <table class="table table-bordered">
      <thead>
        <tr><th>Hours</th><th>Successes / Failures</th></tr>
      </thead>
      <tbody>
        <xsl:apply-templates select="Today/Login[generate-id(.)=generate-id(key('tod', substring(@TS,12,2))[1])]"/>
      </tbody>
    </table>
    <h2>
      Yesterday's connection rates per hour <span style="font-size:75%">(<xsl:value-of select="count(Yesterday/Login[text() = 'success'])"/>/<xsl:value-of select="count(Yesterday/Login[text() = 'failure'])"/>)</span>
    </h2>
    <table class="table table-bordered">
      <thead>
        <tr><th>Hours</th><th>Successes / Failures</th></tr>
      </thead>
      <tbody>
        <xsl:apply-templates select="Yesterday/Login[generate-id(.)=generate-id(key('yes', substring(@TS,12,2))[1])]"/>
      </tbody>
    </table>
    <h2>
      Connection rates per hour (on <xsl:value-of select="All/@Days"/> days average) <span style="font-size:75%">(<xsl:value-of select="format-number(count(All/Login[text() = 'success'])div number(All/@Days),'0')"/>/<xsl:value-of select="format-number(count(All/Login[text() = 'failure']) div number(All/@Days),'0')"/>)</span>
    </h2>
    <table class="table table-bordered">
      <thead>
        <tr><th>Date</th><th>Successes / Failures</th></tr>
      </thead>
      <tbody>
        <xsl:apply-templates select="All/Login[generate-id(.)=generate-id(key('all', substring(@TS,12,2))[1])]">
        </xsl:apply-templates>
      </tbody>
    </table>
  </xsl:template>
  
  <xsl:template match="All/Login">
    <tr>
      <td><xsl:value-of select="substring(@TS,12,2)"/></td>
      <td>
        <span style="color:green">
          <xsl:value-of select="format-number(count(key('alls',substring(@TS,12,2)))  div number(../@Days),'0')"/>
        </span>
        /
        <span style="color:red">
          <xsl:value-of select="format-number(count(key('allf',substring(@TS,12,2)))  div number(../@Days),'0')"/>
        </span>
        
      </td>
    </tr>
  </xsl:template>
  <xsl:template match="Login">
    <xsl:variable name="key">
      <xsl:choose>
        <xsl:when test="local-name(..) = 'Today'">tod</xsl:when>
        <xsl:otherwise>yes</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
      <tr>
        <td><xsl:value-of select="substring(@TS,12,2)"/></td>
        <td>
            <span style="color:green">
              <xsl:value-of select="count(key(concat($key,'s'), substring(@TS,12,2)))"/>
            </span>
            /
            <span style="color:red">
              <xsl:value-of select="count(key(concat($key,'f'), substring(@TS,12,2)))"/>
            </span>
          
        </td>
      </tr>
  </xsl:template>
  
</xsl:stylesheet> 
