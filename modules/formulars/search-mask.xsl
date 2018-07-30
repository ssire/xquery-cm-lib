<?xml version="1.0" encoding="UTF-8"?>
<!--
     XQuery Content Management Library

     Author: Stéphane Sire <s.sire@opppidoc.fr>

     Generate tabular views for search formulars

     August 2014 - (c) Copyright 2014 Oppidoc SARL. All Rights Reserved.
  -->

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xt="http://ns.inria.org/xtiger"
                xmlns:site="http://oppidoc.com/oppidum/site"
                xmlns="http://www.w3.org/1999/xhtml">

  <xsl:template match="SearchMask">
    <xsl:apply-templates select="Title"/>
    <table class="table table-bordered">
      <xsl:apply-templates select="Group | Include" mode="smask">
        <xsl:with-param name="first-column-style">
            <xsl:choose>
              <xsl:when test="@FirstColumnWidth">width:<xsl:value-of select="@FirstColumnWidth"/></xsl:when>
              <xsl:otherwise>width:25%</xsl:otherwise>
            </xsl:choose>
        </xsl:with-param>
        <xsl:with-param name="third-column-style">
            <xsl:choose>
              <xsl:when test="@ThirdColumnWidth">width:<xsl:value-of select="@ThirdColumnWidth"/></xsl:when>
              <xsl:otherwise>width:25%</xsl:otherwise>
            </xsl:choose>
        </xsl:with-param>
      </xsl:apply-templates>
    </table>
  </xsl:template>

  <xsl:template match="Include" mode="smask">
    <xsl:param name="first-column-style"/>
    <xsl:param name="third-column-style"/>
    <xsl:variable name="name"><xsl:value-of select="@Name"/></xsl:variable>
    <xsl:apply-templates select="document(concat($xslt.base-root, concat($xslt.base-formulars, @src)))//Component[@Name = $name]/*" mode="smask">
      <xsl:with-param name="first-column-style"><xsl:value-of select="$first-column-style"/></xsl:with-param>
      <xsl:with-param name="third-column-style"><xsl:value-of select="$third-column-style"/></xsl:with-param>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="Line" mode="smask">
    <xsl:variable name="key"><xsl:value-of select="@Key"/></xsl:variable>
    <tr>
      <td><xsl:copy-of select="Title/@loc"/><xsl:value-of select="Title/text()"/><xsl:apply-templates select="/Form/Hints/Hint[contains(@Keys, $key)]"/></td>
      <td colspan="2"><xsl:apply-templates select="Field"/></td>
    </tr>
  </xsl:template>

  <xsl:template match="Group" mode="smask">
    <xsl:param name="first-column-style"/>
    <xsl:param name="third-column-style"/>
    <tr>
      <td class="group" style="{$first-column-style}" rowspan="{count(descendant::Criteria) - (count(descendant::SubGroup/Criteria) + count(descendant::Criteria[preceding-sibling::*[1][local-name() = 'SubGroup']]))}"><xsl:copy-of select="Title/@loc"/><xsl:value-of select="string(Title/@loc)"/></td>
      <xsl:apply-templates select="Criteria[1]" mode="smask-row">
        <xsl:with-param name="third-column-style"><xsl:value-of select="$third-column-style"/></xsl:with-param>
      </xsl:apply-templates>
    </tr>
    <xsl:apply-templates select="SubGroup | Criteria[position() > 1]" mode="smask-row">
      <xsl:with-param name="first-column-style"><xsl:value-of select="$first-column-style"/></xsl:with-param>
      <xsl:with-param name="third-column-style"><xsl:value-of select="$third-column-style"/></xsl:with-param>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="SubGroup" mode="smask-row">
    <xsl:param name="first-column-style"/>
    <xsl:param name="third-column-style"/>
    <tr>
      <td class="subgroup" style="{$first-column-style}" rowspan="{count(Criteria) + count(following-sibling::Criteria)}"><xsl:value-of select="Title/text()"/></td>
      <xsl:apply-templates select="Criteria[1]" mode="smask-row">
        <xsl:with-param name="third-column-style"><xsl:value-of select="$third-column-style"/></xsl:with-param>
      </xsl:apply-templates>
    </tr>
    <xsl:apply-templates select="Criteria[position() > 1]" mode="smask-row">
      <xsl:with-param name="third-column-style"><xsl:value-of select="$third-column-style"/></xsl:with-param>
    </xsl:apply-templates>
  </xsl:template>

  <!-- Criteria stub with <tr> generation  -->
  <xsl:template match="Criteria" mode="smask-row">
    <xsl:param name="third-column-style"/>
    <tr>
      <xsl:apply-templates select=".">
        <xsl:with-param name="third-column-style" select="$third-column-style"/>
      </xsl:apply-templates>
    </tr>
  </xsl:template>

  <!-- Criteria stub w/o <tr> generation -->
  <xsl:template match="Criteria[1]" mode="smask-row">
    <xsl:param name="third-column-style"/>
    <xsl:apply-templates select=".">
      <xsl:with-param name="third-column-style" select="$third-column-style"/>
    </xsl:apply-templates>
  </xsl:template>

  <!-- Criteria generation -->
  <xsl:template  match="Criteria">
    <xsl:param name="third-column-style"/>
    <xsl:variable name="key"><xsl:value-of select="@Key"/></xsl:variable>
    <xsl:variable name="tag"><xsl:value-of select="@Tag"/></xsl:variable>
    <td>
      <xsl:copy-of select="@loc"/>
      <xsl:choose>
        <xsl:when test="@loc">[ <xsl:value-of select="@loc"/> ]</xsl:when>
        <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
      </xsl:choose>
    </td>
    <td style="{$third-column-style}">
      <xsl:copy-of select="@*[starts-with(local-name(.), 'data-')]"/>
      <xsl:choose>
        <xsl:when test="/Form/Plugins/*[contains(@Keys, $key) or (@Prefix and starts-with($key, @Prefix))]">
          <xsl:apply-templates select="/Form/Plugins/*[contains(@Keys, $key) or (@Prefix and starts-with($key, @Prefix))]">
              <xsl:with-param name="key"><xsl:value-of select="$key"/></xsl:with-param>
              <xsl:with-param name="tag"><xsl:value-of select="$tag"/></xsl:with-param>
          </xsl:apply-templates>
        </xsl:when>
        <xsl:when test="/Form/Plugins/Component/*[contains(@Keys, $key) or (@Prefix and starts-with($key, @Prefix))]">
          <xsl:apply-templates select="/Form/Plugins/Component/*[contains(@Keys, $key) or (@Prefix and starts-with($key, @Prefix))]">
              <xsl:with-param name="key"><xsl:value-of select="$key"/></xsl:with-param>
              <xsl:with-param name="tag"><xsl:value-of select="$tag"/></xsl:with-param>
          </xsl:apply-templates>
        </xsl:when>        
        <xsl:otherwise>
          <div class="span12">
            <xsl:choose>
              <xsl:when test="$xslt.goal = 'save'">
                <site:field force="true">
                  <xsl:copy-of select="@Key | @Tag | @Placeholder-loc"/>
                  <xsl:value-of select="$key"/>[<xsl:value-of select="@Tag"/>]
                </site:field>
              </xsl:when>
              <xsl:otherwise>
                <xt:use types="t_fake_field" label="{@Tag}"/>
              </xsl:otherwise>
            </xsl:choose>
          </div>
        </xsl:otherwise>
      </xsl:choose>
    </td>
  </xsl:template>

  <!-- ************************* -->
  <!--         Plugins           -->
  <!-- ************************* -->

  <!-- ========================= -->
  <!--          Period           -->
  <!-- ========================= -->
  <!-- we could replace @Prefix with @Use to create an intermediate component/tag instead -->
  <xsl:template match="Period">
    <div style="text-align:left">
      <xsl:apply-templates select="@Interval" mode="period"/>
      <div style="display:inline">
        <xsl:if test="@Interval">
          <xsl:attribute name="data-min-date"><xsl:value-of select="@Interval"/></xsl:attribute>
        </xsl:if>
        <xsl:apply-templates select="@From" mode="period"/>
        <xt:use types="input" label="{@Prefix}StartDate" param="type=date;date_region=fr;date_format=ISO_8601;filter=optional;maxDate=today;class=date span3"></xt:use>
      </div>
      <div style="display:inline">
        <xsl:if test="@Interval">
          <xsl:attribute name="data-max-date"><xsl:value-of select="@Interval"/></xsl:attribute>
        </xsl:if>
        <xsl:apply-templates select="@To" mode="period"/>
        <xt:use types="input" label="{@Prefix}EndDate" param="type=date;date_region=fr;date_format=ISO_8601;filter=optional;maxDate=today;class=date span3"></xt:use>
      </div>
    </div>
  </xsl:template>
  
  <xsl:template match="@Interval" mode="period">
    <xsl:attribute name="data-binding">interval</xsl:attribute>
    <xsl:attribute name="data-variable"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <!-- TODO: localize -->
  <xsl:template match="@From" mode="period">
    <span style="padding-right:10px" loc="interval.date.from"><xsl:value-of select="."/></span>
  </xsl:template>

  <!-- TODO: localize -->
  <xsl:template match="@To" mode="period">
    <span style="padding-left:20px; padding-right:10px" loc="interval.date.to"><xsl:value-of select="."/></span>
  </xsl:template>

  <!-- we could replace @Prefix with @Use to create an intermediate component/tag instead -->
  <xsl:template match="Period[@Span = 'Year']">
    <div style="text-align:left">
      <span style="padding-right:10px" loc="range.between">between</span>
      <site:field Size="2" Key="creation-year" Tag="{@Prefix}StartYear" force="true"/>
      <span style="padding-left:20px; padding-right:10px" loc="range.and">and</span>
      <site:field Size="2" Key="creation-year" Tag="{@Prefix}EndYear" force="true"/>
    </div>
  </xsl:template>

  <!-- ========================= -->
  <!--          MinMax           -->
  <!-- ========================= -->

  <xsl:template match="MinMax">
    <xsl:param name="key">key</xsl:param>
    <xsl:param name="tag">Tag</xsl:param>
    <xt:use types="t_{../@Name}" label="{$tag}"/>
  </xsl:template>

  <!-- TODO:
      - parameterize span2 ?
      - non Component mode ?
  -->
  <xsl:template match="MinMax" mode="component">
    <xt:component name="t_{../@Name}">
      <div style="text-align:left">
        <xsl:apply-templates select="@Min" mode="period"/>
        <xt:use types="input" label="Min" param="type=number;filter=optional;class=span2 a-control;xvalues=min"></xt:use>
        <xsl:apply-templates select="@Max" mode="period"/>
        <xt:use types="input" label="Max" param="type=number;filter=optional;class=span2 a-control;xvalues=max"></xt:use>
      </div>
    </xt:component>
  </xsl:template>

  <!-- TODO: localize -->
  <xsl:template match="@Min" mode="period">
    <span style="padding-right:5px" loc="range.gte"><xsl:value-of select="."/></span>
  </xsl:template>

  <!-- TODO: localize -->
  <xsl:template match="@Max" mode="period">
    <span style="padding-left:10px; padding-right:10px" loc="range.lte"><xsl:value-of select="."/></span>
  </xsl:template>

</xsl:stylesheet>
