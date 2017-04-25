<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:site="http://oppidoc.com/oppidum/site"
  xmlns="http://www.w3.org/1999/xhtml">

  <xsl:output method="xml" media-type="text/html" omit-xml-declaration="yes" indent="yes"/>

  <xsl:template match="/">
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template match="error">
    <p><xsl:value-of select="message"/></p>
  </xsl:template>

  <!-- Email implies a Sender (automatically filled) and a From field (editable by real sender user) -->
  <!-- To and Addressees should be exclusive one of each other -->
  <xsl:template match="Alert">
    <div>
      <p style="position:relative">
        <span style="float:left;width:5em;text-align:right;">From :</span><xsl:apply-templates select="Sender"/>
        <span style="float:left;width:5em;text-align:right">Subject :</span><div style="margin-left: 5.5em"><xsl:value-of select="Subject"/></div>
        <span style="float:left;width:5em;text-align:right">Date :</span><div style="margin-left: 5.5em"><xsl:value-of select="Date"/></div>
        <span style="float:left;width:5em;text-align:right">To :</span><div style="margin-left: 5.5em"><xsl:apply-templates  select="To | Addressees"/></div>
        <xsl:apply-templates select="CC"/>
      </p>
      <hr/>
      <xsl:apply-templates select="/Alert/*/DefaultContent"/>
      <h4>Message :</h4>
      <xsl:apply-templates select="/Alert/*/Message"/>
      </div>
      <xsl:apply-templates select="/Alert/*/Attachment"/>
  </xsl:template>

  <xsl:template match="Sender">
    <div style="margin-left: 5.5em"><xsl:value-of select="."/></div>
  </xsl:template>

  <xsl:template match="Sender[. != ''][../From]">
    <div style="margin-left: 5.5em"><xsl:value-of select="../From"/> (authored by <xsl:value-of select="."/>)</div>
  </xsl:template>

  <xsl:template match="Sender[. != ''][@Mode = 'batch'][../From]">
    <div style="margin-left: 5.5em"><xsl:value-of select="../From"/> (batch run by <xsl:value-of select="."/>)</div>
  </xsl:template>

  <xsl:template match="Sender[. = ''][not(../To)]">
    <div style="margin-left: 5.5em"><i>unregistered user</i></div>
  </xsl:template>

  <xsl:template match="Sender[. = ''][@Mode = 'auto']">
    <div style="margin-left: 5.5em">case tracker reminder</div>
  </xsl:template>

  <xsl:template match="Sender[. != ''][@Mode = 'auto']">
    <div style="margin-left: 5.5em">case tracker reminder (run by <xsl:value-of select="."/>)</div>
  </xsl:template>
  
  <xsl:template match="To"><xsl:value-of select="."/>
  </xsl:template>

  <xsl:template match="Addressees"><xsl:text>, </xsl:text><xsl:value-of select="."/>
  </xsl:template>

  <xsl:template match="Addressees[not(../To)]"><xsl:value-of select="."/>
  </xsl:template>
  
  <xsl:template match="CC">
    <span style="float:left;width:5em;text-align:right">Cc :</span><div style="margin-left: 5.5em"><xsl:value-of select="."/></div>    
  </xsl:template>

  <xsl:template match="Text">
    <p><xsl:value-of select="."/></p>
  </xsl:template>

  <xsl:template match="Message">
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template match="Block">
    <p>
      <xsl:apply-templates select="Line"/>
    </p>
  </xsl:template>

  <xsl:template match="Line"><xsl:value-of select="."/><br/>
  </xsl:template>

  <xsl:template match="Line[position() = last()]"><xsl:value-of select="."/>
  </xsl:template>

  <!-- DEPRECATED -->
  <xsl:template match="DefaultContent">
    <h4>System notification :</h4>
    <p><xsl:value-of select="."/></p>
  </xsl:template>

  <xsl:template match="Attachment">
    <pre style="word-break:normal">
      <xsl:copy-of select="./text()"/>
    </pre>
  </xsl:template>
</xsl:stylesheet>
