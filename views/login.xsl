<?xml version="1.0" encoding="UTF-8"?>
<!--
     XQuery Content Management Library

     Creator: Stéphane Sire <s.sire@opppidoc.fr>

     Login form generation

     Turns a <Login> model to a <site:content> module containing a login dialog
     box. Does nothing if the model contains a <Redirected> element (e.g. as a
     consequence of a successful login when handling a POST - see login.xql).

     November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
  -->
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:site="http://oppidoc.com/oppidum/site"
  xmlns="http://www.w3.org/1999/xhtml">

  <xsl:output method="xml" media-type="text/html" omit-xml-declaration="yes" indent="yes"/>

  <!-- integrated URL rewriting... -->
  <xsl:param name="xslt.base-url"></xsl:param>

  <xsl:template match="/">
    <site:view>
      <site:window><title>Case Tracker Login</title></site:window>
      <xsl:apply-templates select="*"/>
    </site:view>
  </xsl:template>

  <!-- Login dialog box -->
  <xsl:template match="Login[not(Redirected)]">
    <site:content>
        <div class="row login">
          <div>
            <xsl:apply-templates select="." mode="layout"/>
            <form class="form-horizontal" action="{$xslt.base-url}login?url={To}" method="post">
              <fieldset>
                <legend loc="login.title">Identification</legend>
                <xsl:apply-templates select="Hold"/>
                <xsl:apply-templates select="Check"/>
                <div class="control-group">
                  <label class="control-label" for="login-user" loc="login.user">Nom d'utilisateur</label>
                  <div class="controls">
                    <input id="login-user" required="1" type="text" name="user" value="{User}"/>
                  </div>
                </div>
                <div class="control-group">
                  <label class="control-label" for="login-passwd" loc="login.pwd">Mot de passe</label>
                  <div class="controls">
                    <input id="login-passwd" required="1" type="password" name="password"/>
                  </div>
                </div>
                <div class="control-group" id="submit">
                  <div class="controls">
                    <input type="submit" class="btn"/>
                  </div>
                </div>
                <xsl:if test="not(Hold)">
                  <div class="row" style="margin-top:2em;margin-left:0">
                    <div class="span2"><a href="about">About</a></div>
                    <div class="span2"><a href="me/forgotten" title-loc="login.forgotten.hint" loc="login.forgotten">mot de passe oublié</a></div>
                    <xsl:apply-templates select="ECAS"/>
                  </div>
                </xsl:if>
            </fieldset>
          </form>
        </div>
      </div>
    </site:content>
  </xsl:template>
  
  <xsl:template match="Login" mode="layout">
    <xsl:attribute name="class">span6 offset3</xsl:attribute>
  </xsl:template>

  <xsl:template match="Login[ECAS]" mode="layout">
    <xsl:attribute name="class">span7 offset3</xsl:attribute>
  </xsl:template>

  <xsl:template match="Login[Redirected]">
    <p>Goto <a href="{Redirected}"><xsl:value-of select="Redirected"/></a></p>
  </xsl:template>
  
  <xsl:template match="Login[SuccessfulMerge]">
    <p>Goto <a href="{SuccessfulMerge}"><xsl:value-of select="SuccessfulMerge"/></a></p>
  </xsl:template>
  
  <xsl:template match="Check">
    <p class="text-warning" style="font-size:150%;line-height: 1.5;text-align:center" loc="login.check">Your user profile cannot be located</p>
  </xsl:template>
  
  <xsl:template match="Hold">
    <p class="text-warning" style="font-size:150%;line-height: 1.5;text-align:center" loc="login.hold">Please come back in a few minutes ...</p>
  </xsl:template>

  <!-- FIXME: Url ? -->
  <xsl:template match="ECAS">
    <xsl:variable name="url"><xsl:value-of select="../Url"/></xsl:variable>
    <div class="span2" style="float:right">
      <xsl:choose>
        <xsl:when test="../Url != ''">
          <a href="login?url={$url}&amp;ecas=1">ECAS login</a>
        </xsl:when>
        <xsl:otherwise>
          <a href="login?ecas=init">ECAS login</a>
        </xsl:otherwise>
      </xsl:choose>
    </div>
  </xsl:template>
</xsl:stylesheet>
