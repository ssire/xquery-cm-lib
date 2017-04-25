<?xml version="1.0" encoding="UTF-8"?>
<!--
     XQuery Content Management Library

     Creator: Stéphane Sire <s.sire@opppidoc.fr>

     User password tunnel views generation

     March 2014 - (c) Copyright 2014 Oppidoc SARL. All Rights Reserved.
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
      <site:window><title>User account management</title></site:window>
      <xsl:apply-templates select="Display/*"/>
    </site:view>
  </xsl:template>

  <xsl:template match="AskUserHint">
    <site:content>
        <div class="row login">
          <div class="span6 offset3">
            <form class="form-horizontal" action="{Controller}" method="post">
              <fieldset>
              <legend loc="pwd.title">Mot de passe oublié</legend>
              <p loc="pwd.hint">Pour recevoir un nouveau mot de passe veuillez indiquer votre nom d'utilisateur dans le champ ci-dessous, ainsi que l'adresse sous laquelle vous êtes enregistré dans l'application</p>
              <div class="control-group">
                <label class="control-label" for="login-user" loc="login.user">Nom d'utilisateur</label>
                <div class="controls">
                  <input id="login-user" required="1" type="text" name="user" value=""/>
                </div>
              </div>
              <div class="control-group">
                <label class="control-label" for="login-user" loc="pwd.email">Courrier électronique</label>
                <div class="controls">
                  <input type="email" required="1" name="mail" value=""/>
                </div>
              </div>
              <div class="control-group" id="submit">
                <div class="controls">
                  <input type="submit" class="btn" value-loc="action.new.pwd"/>
                  <a class="btn" href="../login?url={$xslt.base-url}stage" loc="action.cancel">Annuler</a>
                </div>
              </div>
            </fieldset>
          </form>
        </div>
      </div>
    </site:content>
  </xsl:template>

  <xsl:template match="AskUserPassword">
    <site:content>
        <div class="row login">
          <div class="span7 offset3">
            <form class="form-horizontal" action="{Controller}" method="post">
              <fieldset>
              <legend loc="account.title">Gestion du compte utilisateur</legend>
              <p><span loc="account.identity1">Vous êtes connecté(e) en tant que</span> "<xsl:value-of select="Username"/>" <span loc="account.identity2">et vous devez être</span> "<xsl:value-of select="Name"/>".</p>
              <p loc="account.pwd.hint">Vous pouvez modifier votre mot de passe à l'aide du formulaire ci-dessous. Attention, il doit contenir au minimum 8 caractères. Les espaces en début et en fin ne seront pas pris en compte.</p>
              <div class="control-group">
                <label class="control-label" loc="account.pwd">Nouveau mot de passe</label>
                <div class="controls">
                  <input required="1" type="text" name="change" value=""/>
                </div>
              </div>
              <div class="control-group">
                <label class="control-label" loc="account.pwd.bis" >Mot de passe (répétition)</label>
                <div class="controls">
                  <input required="1" type="text" name="check" value=""/>
                </div>
              </div>              
              <div class="control-group" id="submit">
                <div class="controls">
                  <input type="submit" class="btn" value-loc="action.submit.pwd"/>
                  <a class="btn" href="stage" loc="action.cancel">Annuler</a>
                </div>
              </div>
            </fieldset>
          </form>
        </div>
      </div>
    </site:content>
  </xsl:template>

  <xsl:template match="New">
    <site:content>
        <div class="row login">
          <div class="span7 offset3">
            <p><span loc="pwd.sentByEmail">Votre nouveau mot de passe a été envoyé à</span> <xsl:value-of select="Email"/></p>
            <p class="text-right"><a href="../login?url={$xslt.base-url}stage" class="btn" loc="action.back">Retour</a></p>
          </div>
        </div>
    </site:content>
  </xsl:template>
  
  <xsl:template match="Changed">
    <site:content>
        <div class="row login">
          <div class="span7 offset3">
            <p loc="pwd.updated">Votre nouveau mot de passe a bien été enregistré</p>
            <p loc="account.continue.hint">Utilisez le nouveau mot de passe dès votre prochaine demande de connexion</p>
            <p class="text-right"><a href="{$xslt.base-url}stage" class="btn" loc="action.continue">Continuer</a></p>
          </div>
        </div>
    </site:content>
  </xsl:template>
</xsl:stylesheet>
