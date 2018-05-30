<?xml version="1.0" encoding="UTF-8"?>
<!--
    XQuery Content Management Library

     Author: Stéphane Sire <s.sire@opppidoc.fr>

     Shared search page building blocks

     Vocabulary:
     [mode=""] Formular, Null, Empty, NotAvailable
     [mode="ct_search_legacy"] Modals, View, Edit, Create

     November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
  -->
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:site="http://oppidoc.com/oppidum/site"
  xmlns="http://www.w3.org/1999/xhtml">
  
  <!-- Called from /stage
       DEPRECATED: to be unified with Formular from widget vocabulary instead 
       -->
  <xsl:template name="formular">
    <form class="form-horizontal c-search" action="" onsubmit="return false;">
      <div id="editor" data-template="templates/search/{/Search/@Controller}?goal=update" data-src="{/Search/@Controller}/submission">
        <noscript loc="app.message.js">Activez Javascript</noscript>
        <p loc="app.message.loading">Chargement du formulaire en cours</p>
      </div>
      <div class="row c-search-menu">
        <button onclick="javascript:$('#c-busy').show()" style="float:right;margin-right:5px; margin-bottom:5px;min-width: 150px" data-command="save" data-replace-target="results" data-target="editor" data-src="{/Search/@Controller}" data-save-flags="disableOnSave silentErrors" class="btn btn-primary" loc="action.search">Rechercher</button>
        <div class="span6" style="margin: 2px 0 5px 25px">
          <button class="btn btn-small" onclick="$.ajax({{type:'post',url:'{/Search/@Controller}/submission',data:$axel('#editor').xml(),dataType:'xml',contentType:'application/xml; charset=UTF-8'}});return false;" loc="action.save.submission">Sauver</button>
          <button class="btn btn-small" onclick="$axel('#editor').load('{/Search/@Controller}/submission');return false;" loc="action.load.submission">Requête sauvée</button>
          <button class="btn btn-small" onclick="$axel('#editor').load('&lt;SearchStageRequest/&gt;');return false;" loc="action.reset">Effacer</button>          
        </div>
      </div>
    </form>
  </xsl:template>

  <xsl:template match="NoRequest">
  </xsl:template>

  <xsl:template match="RequestReady"><p id="c-req-ready" style="text-align:center"><i>Default request filter loaded, hit Search to execute it</i></p>
  </xsl:template>

  <xsl:template match="Null">
    <h2 loc="app.title.noResults">Pas de résultats</h2>
    <p><i loc="app.hint.noResults">Choisissez un ou plusieurs critères avant de lancer une recherche.</i></p>
    <p><i loc="app.hint.saveSearch">Vous pouvez sauvegarder une recherche avec le bouton “Sauver”, celle-ci sera lancée chaque fois que vous revenez sur la page. Vous pourrez également la rappeler avec le bouton “Requête sauvée”.</i></p>
  </xsl:template>

  <xsl:template match="Empty">
    <h2 loc="app.title.noResults">Pas de résultats</h2>
    <p><i loc="app.message.noResults">Il n'y a pas de résultats pour les critères sélectionnés.</i></p>
  </xsl:template>

  <xsl:template match="NotAvailable">
    <h2 loc="app.title.noResults">Pas de résultats</h2>
    <p><i>Cette fonctionnalité de recherche n'est pas encore disponible.</i></p>
  </xsl:template>

</xsl:stylesheet>
