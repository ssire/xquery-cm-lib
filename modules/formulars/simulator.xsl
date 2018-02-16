<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:site="http://oppidoc.com/oppidum/site"
  xmlns="http://www.w3.org/1999/xhtml">

  <xsl:output method="xml" media-type="text/html" omit-xml-declaration="yes" indent="yes"/>

  <!-- Parameters (can be set on command line) -->
  <xsl:param name="xslt.base-url">resources/</xsl:param>
  <xsl:param name="xslt.lang">fr</xsl:param>
  <xsl:param name="xslt.rights"></xsl:param>

  <xsl:template match="/">
    <xsl:variable name="schematize">
      <xsl:if test="contains(/Formulars/@Options, 'schematize')"><xsl:text> </xsl:text>schematize</xsl:if>
    </xsl:variable>
    <site:view skin="formulars{$schematize}">
      <site:content>
        <h1 class="noprint">Supergrid form generator</h1>
        <form class="noprint" style="background-color:#F7E9D4;margin-bottom:2em" action="" onsubmit="return false;">
          <div class="row-fluid">
              <div class="span10">
                <div class="control-group">
                  <label class="control-label a-gap2">Form</label>
                  <div class="controls">
                    <xsl:apply-templates select="Formulars"/>
                    <button id="x-test" class="btn btn-primary">Test</button>
                    <button id="x-control" class="btn">Control</button>
                    <button id="x-dump" class="btn">Dump</button>
                    <xsl:if test="contains(/Formulars/@Options, 'schematize')">
                      <button id="x-schema" class="btn">Schema</button>
                    </xsl:if>
                  </div>
                </div>
              </div>
              <!-- TO BE REWRITTEN (FIREFOX no more supports view-source protocol)
                <div class="span4">
                  <div style="float:right">
                    <button id="x-src" class="btn btn-warning">Source</button>
                    <button id="x-generate" class="btn btn-warning">Générer</button>
                    <button id="x-model" class="btn btn-warning">Modèle</button>
                  </div>
                </div> -->
          </div>
          <div class="row-fluid">
              <div class="span5">
                <div class="control-group">
                  <label class="control-label a-gap2">Online version</label>
                  <div class="controls">
                    <button id="x-display" class="btn">Show</button>
                    <button id="x-validate" class="btn">Validate</button>
                    <xsl:if test="$xslt.rights = 'install'">
                      <button id="x-install" class="btn btn-small btn-primary">Install</button>
                    </xsl:if>
                  </div>
                </div>
              </div>
              <div class="span3">
                <div class="control-group">
                  <label class="control-label a-gap1">Mode</label>
                  <div class="controls">
                    <select id="x-mode">
                      <option value="read">read</option>
                      <option value="create">create</option>
                      <option value="update">update</option>
                    </select>
                  </div>
                </div>
              </div>
              <xsl:if test="$xslt.rights = 'install'">
                <div class="span4">
                  <div style="float:right">
                    <button id="x-install-all" class="btn btn-danger">Install all</button>
                  </div>
                </div>
              </xsl:if>
          </div>
        </form>
        <div id="c-editor-errors" class="alert alert-error af-validation">
          <button type="button" class="close" data-dismiss="alert">x</button>
        </div>
        <div id="x-simulator" class="c-editing-mode" data-axel-base="{$xslt.base-url}" >
          <noscript>Activate Javascript</noscript>
          <p>Formular generation area</p>
        </div>
        <div class="noprint">
          <h2 style="text-align:left">Notes</h2>
          <ul>
          <li><i>Form</i> shows formulars registered inside <tt>formulars/_register.xml</tt></li>
          <li><i>Test</i> replaces dynamical extension points with static drop down selector for fast checking</li>
          <li><i>Control</i> shows field keys, XML output model tags and Gap width; each field key must match a <code>&lt;site:field Key="key"></code> element generated from the formular template <tt>form.xql</tt> model</li>
          <li><i>Dump</i> gives an XML output model preview (click on <i>Test</i> or <i>Show</i> a formular first)</li>
          <li>more documentation available in the case tracker software documentation <a href="https://github.com/ssire/case-tracker-manual/blob/master/doc/supergrid-use.md">Supergrid use</a> chapter</li>
          </ul>
        </div>
      </site:content>
    </site:view>
  </xsl:template>

  <xsl:template match="Formulars">
    <select id="x-formular">
      <xsl:apply-templates select="Formular"/>
    </select>
  </xsl:template>

  <xsl:template match="Formular">
    <option value="{Form}"><xsl:value-of select="Name"/></option>
  </xsl:template>

  <xsl:template match="Formular[Template]">
    <option data-display="{Template}" value="{Form}"><xsl:value-of select="Name"/></option>
  </xsl:template>
</xsl:stylesheet>
