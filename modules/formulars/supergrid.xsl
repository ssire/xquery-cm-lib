<?xml version="1.0" encoding="UTF-8" ?>
<!--
     XQuery Content Management Library

     Author: Stéphane Sire <s.sire@opppidoc.fr>

     Supergrid transformation entry point

     Copy this file into your project to extend supergrid with your own vocabulary/modules

     April 2017 - (c) Copyright 2017 Oppidoc SARL. All Rights Reserved.
  -->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xt="http://ns.inria.org/xtiger"
  xmlns:site="http://oppidoc.com/oppidum/site"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  >

  <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="yes" />

  <!-- Inherited from Oppidum pipeline -->
  <xsl:param name="xslt.base-url"></xsl:param>

  <!-- Query "goal" parameter transmitted by Oppidum pipeline -->
  <xsl:param name="xslt.goal">test</xsl:param>

  <!-- Transmitted by formulars/install.xqm-->
  <xsl:param name="xslt.base-root"></xsl:param> <!-- for Include -->

  <!-- CONFIGURE this to fit your project -->
  <xsl:param name="xslt.app-name">pilote</xsl:param>
  <xsl:param name="xslt.base-formulars">webapp/projects/pilote/formulars/</xsl:param> <!-- for Include -->

  <xsl:include href="search-mask.xsl"/>
  <xsl:include href="supergrid-core.xsl"/>
</xsl:stylesheet>  