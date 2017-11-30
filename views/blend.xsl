<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns:xhtml="http://www.w3.org/1999/xhtml">

  <xsl:output indent="yes"/>

  <xsl:template match="/">
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template
    match="*|@*|comment()|processing-instruction()|text()">
    <xsl:copy>
      <xsl:apply-templates
        select="*|@*|comment()|processing-instruction()|text()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="Text">
    <xhtml:p><xsl:value-of select="."/></xhtml:p>
  </xsl:template>

  <!-- FIXME: DEPRECATED ? -->
  <xsl:template match="ContextDescription">
    <ContextDescription>
      <xsl:apply-templates select="*"/>
    </ContextDescription>
  </xsl:template>
  
  <!-- FIXME: move to local application version ? -->
  <xsl:template match="Summary[Text]">
    <xsl:copy>
      <xsl:apply-templates select="*"/>
    </xsl:copy>
  </xsl:template>

  <!-- FIXME: move to local application version ? -->
  <xsl:template match="Description[Text]">
    <xsl:copy>
      <xsl:apply-templates select="*"/>
    </xsl:copy>
  </xsl:template>

  <!--///////////////////////
    Rich Text block
    ///////////////////////-->

  <xsl:template match="Title">
    <xhtml:h3>
      <xsl:value-of select="."/>
    </xhtml:h3>
  </xsl:template>

  <xsl:template match="Parag">
    <xhtml:p class="parag">
      <xsl:apply-templates select="Fragment | Link | text()"/>
    </xhtml:p>
  </xsl:template>

  <xsl:template match="Fragment[@FragmentKind = 'verbatim']">
    <xhtml:span class="verbatim"><xsl:value-of select="."/></xhtml:span>
  </xsl:template>

  <xsl:template match="Fragment[@FragmentKind = 'important']">
    <xhtml:span class="important"><xsl:value-of select="."/></xhtml:span>
  </xsl:template>

  <xsl:template match="Fragment[@FragmentKind = 'emphasize']">
    <xhtml:span class="emphasize"><xsl:value-of select="."/></xhtml:span>
  </xsl:template>  

  <xsl:template match="Fragment">
    <xsl:value-of select="."/>
  </xsl:template>

  <!-- External links open in a new window -->
  <xsl:template match="Link">
    <xsl:choose>
      <xsl:when test="starts-with(LinkRef, 'http:') or starts-with(LinkRef, 'https:')">
        <xhtml:a href="{LinkRef}" target="_blank"><xsl:value-of select="LinkText"/></xhtml:a>
      </xsl:when>
      <xsl:otherwise>
        <xhtml:a href="{LinkRef}"><xsl:value-of select="LinkText"/></xhtml:a>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="List">
    <xsl:apply-templates select="ListHeader"/>
    <xhtml:ul class="x-List">
      <xsl:apply-templates select="./Item | ./SubList"/>
    </xhtml:ul>
  </xsl:template>

  <xsl:template match="ListHeader">
    <xhtml:p class="x-ListHeader">
      <xsl:value-of select="."/> :
    </xhtml:p>
  </xsl:template>

  <xsl:template match="Item">
    <xhtml:li>
      <xsl:apply-templates select="*"/>
    </xhtml:li>
  </xsl:template>

  <xsl:template match="SubList">
    <xhtml:ul>
      <xsl:apply-templates/>
    </xhtml:ul>
  </xsl:template>

  <xsl:template match="SubListItem">
    <xhtml:ul>
      <xsl:apply-templates/>
    </xhtml:ul>
  </xsl:template>

  <xsl:template match="SubListHeader">
    <xhtml:li>
      <xsl:value-of select="."/>
    </xhtml:li>
  </xsl:template>

</xsl:stylesheet>
