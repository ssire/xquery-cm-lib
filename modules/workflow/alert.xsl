<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:site="http://oppidoc.com/oppidum/site" xmlns="http://www.w3.org/1999/xhtml">

  <xsl:output method="xml" media-type="application/xhtml+xml" omit-xml-declaration="yes" indent="yes"/>

  <xsl:param name="xslt.base-url">/</xsl:param>

  <xsl:include href="../../lib/commons.xsl"/>
  <xsl:include href="../../modules/workflow/workflow.xsl"/>

  <!-- Calls success or error to return an Ajax response when creating an Alert
       Note: Ajax error should have cut the pipeline because of status code and not reach that code
       -->
  <xsl:template match="/">
    <xsl:apply-templates select="success"/>
  </xsl:template>

</xsl:stylesheet>


