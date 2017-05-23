<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<!-- 
  XQuery Content Management Library

  Author: Stéphane Sire <s.sire@opppidoc.fr>

  Script to convert Selector elements (data types) to CSV tables

  Use it offline with SaxonHE XSLT processor or any other one
  For instance to export data type in data/global-information/reuters-en.xml :

  java -cp {SAXON-HOME}/saxon9he.jar net.sf.saxon.Transform -s:reuters-en.xml -xsl:selector2csv.xsl selector=TargetedMarkets

  TODO: 
    - decode Label through Selector@Label for selectors like Countries
    - manages Selector with Group type in "full" export  
  -->

<xsl:output method="text" encoding="iso-8859-1"/>

<xsl:strip-space elements="*" />

<xsl:param name="selector"/>
<xsl:param name="lang">en</xsl:param>

<xsl:param name="delim" select="','" />
<xsl:param name="quote" select="'&quot;'" />
<xsl:param name="break" select="'&#xA;&#xD;'" />

<xsl:template match="/">
  <xsl:choose>
    <xsl:when test="$selector != ''"><xsl:apply-templates select=".//Description[@Lang = $lang]/Selector[@Name = $selector]"/></xsl:when>
    <xsl:otherwise>
      <xsl:apply-templates select=".//Description[@Lang = $lang]/Selector" mode="full"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="Selector[Group]">
  <xsl:value-of select="concat($quote, 'Code', $quote)" />
  <xsl:value-of select="$delim" />
  <xsl:value-of select="concat($quote, 'Group', $quote)" />
  <xsl:value-of select="$delim" />
  <xsl:value-of select="concat($quote, 'SubCode', $quote)" />
  <xsl:value-of select="$delim" />
  <xsl:value-of select="concat($quote, 'SubGroup', $quote)" />
  <xsl:value-of select="$break" />
  <xsl:apply-templates select="Group" />
</xsl:template>

<xsl:template match="Group">
  <xsl:variable name="code" select="ancestor::Selector/@Value" />
  <xsl:apply-templates select="Selector/Option" mode="hierarchical">
    <xsl:sort select="*[local-name() = $code]" data-type="number"/>
  </xsl:apply-templates>
</xsl:template>

<xsl:template match="Selector[not(Group)]">
  <xsl:variable name="code" select="@Value" />
  <xsl:value-of select="concat($quote, 'Code', $quote)" />
  <xsl:value-of select="$delim" />
  <xsl:value-of select="concat($quote, 'Group', $quote)" />
  <xsl:value-of select="$break" />
  <xsl:apply-templates select="Option" mode="flat">
    <xsl:sort select="*[local-name() = $code]" data-type="number"/>
  </xsl:apply-templates>
</xsl:template>

<!-- First with headers -->
<xsl:template match="Selector[1][not(Group)]" mode="full" priority="1">
  <xsl:variable name="code" select="@Value" />
  <xsl:value-of select="concat($quote, 'Type', $quote)" />
  <xsl:value-of select="$delim" />
  <xsl:value-of select="concat($quote, 'Code', $quote)" />
  <xsl:value-of select="$delim" />
  <xsl:value-of select="concat($quote, 'Group', $quote)" />
  <xsl:value-of select="$break" />
  <xsl:apply-templates select="Option" mode="flat">
    <xsl:sort select="*[local-name() = $code]" data-type="number"/>
  </xsl:apply-templates>

</xsl:template>

<!-- Don't repeat headers -->
<xsl:template match="Selector[not(Group)]" mode="full">
  <xsl:variable name="code" select="@Value" />
  <xsl:apply-templates select="Option" mode="flat">
    <xsl:sort select="*[local-name() = $code]" data-type="number"/>
  </xsl:apply-templates>
</xsl:template>

<xsl:template match="Option" mode="hierarchical">
  <xsl:value-of select="concat($quote, normalize-space(./ancestor::Group/Code), $quote)" />
  <xsl:value-of select="$delim" />
  <xsl:value-of select="concat($quote, normalize-space(./ancestor::Group/Name), $quote)" />
  <xsl:value-of select="$delim" />
  <xsl:value-of select="concat($quote, normalize-space(*[local-name() = ./ancestor::Selector/@Value]), $quote)" />
  <xsl:value-of select="$delim" />
  <xsl:value-of select="concat($quote, normalize-space(Name), $quote)" />
  <xsl:value-of select="$break" />
</xsl:template>

<xsl:template match="Option" mode="flat">
  <xsl:if test="$selector = ''">
    <xsl:value-of select="concat($quote, normalize-space(./ancestor::Selector/@Name), $quote)" />
    <xsl:value-of select="$delim" />
  </xsl:if>
  <xsl:value-of select="concat($quote, normalize-space(*[local-name() = ./ancestor::Selector/@Value]), $quote)" />
  <xsl:value-of select="$delim" />
  <xsl:value-of select="concat($quote, normalize-space(Name), $quote)" />
  <xsl:value-of select="$break" />
</xsl:template>

<xsl:template match="text()" />

</xsl:stylesheet>