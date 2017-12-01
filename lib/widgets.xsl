<?xml version="1.0" encoding="UTF-8"?>
<!-- 
     XQuery Content Management Library

     Author: Stéphane Sire <s.sire@opppidoc.fr>

     Common widget vocabulary for application level user interface

     Last update: 2016-11-25

     November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
  -->
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:site="http://oppidoc.com/oppidum/site"
  xmlns="http://www.w3.org/1999/xhtml">


  <!-- ****************************************** -->
  <!--                TAB GROUPS                  -->
  <!--               (with Group)                 -->
  <!-- ****************************************** -->

  <xsl:template match="TabGroups">
    <div class="tabbable">
      <div style="float:left;width:140px">
        <div class="well" style="width:120px;padding:10px 0 0">
          <div class="nav tabs-left">
            <ul class="nav nav-list tab-groups" style="width:100px">
              <xsl:apply-templates select="Group"/>
            </ul>
          </div>
        </div>
      </div>
      <div class="tab-content">
        <xsl:apply-templates select="Group/Tab"/>
      </div>
    </div>
  </xsl:template>

  <xsl:template match="Group">
    <li class="nav-header"><xsl:value-of select="Name"/></li>
    <xsl:apply-templates select="Tab" mode="nav"/>
  </xsl:template>

  <!-- ****************************************** -->
  <!--               SIMPLE TABS                  -->
  <!--           (with or w/o Group)              -->
  <!-- ****************************************** -->

  <xsl:template match="Tabs">
    <div class="tabbable tabs-left">
      <ul class="nav nav-tabs" style="width:120px">
        <xsl:apply-templates select="Tab|Group/Tab" mode="nav"/>
      </ul>
      <div class="tab-content">
        <xsl:apply-templates select="Tab|Group/Tab"/>
      </div>
    </div>
  </xsl:template>

  <!-- Multi-functions Tab (with or without lazy content with Controller): 
       use class="active" to make it initially visible -->
  <xsl:template match="Tab" mode="nav">
    <li>
      <xsl:copy-of select="@class"/>
      <a href="#c-pane-{@Id}">
        <xsl:apply-templates select="Controller" mode="Tab"/>
        <xsl:if test="not(Controller)">
          <xsl:attribute name="data-toggle">tab</xsl:attribute>
        </xsl:if>
        <xsl:copy-of select="Name/@loc"/>
        <xsl:value-of select="Name"/>
      </a>
    </li>
  </xsl:template>
  
  <!-- Tab with a counter inside label
       (actually incompatible with the lazy content pattern)
       FIXME: @Counter prevents @loc in Name  -->
  <xsl:template match="Tab[@Counter]" mode="nav">
    <xsl:variable name="enum"><xsl:value-of select="string(@Counter)"/></xsl:variable>
    <li>
      <xsl:copy-of select="@class"/>
      <a id="c-counter-{@Id}" href="#c-pane-{@Id}" data-toggle="tab">
        <xsl:value-of select="Name"/> [<xsl:value-of select="count(descendant::*/*[local-name() = $enum])"/>]
      </a>
    </li>
  </xsl:template>

  <!-- Pseudo-tab navigating to a new page -->
  <xsl:template match="Tab[@Link]" mode="nav" priority="1">
    <li>
      <xsl:copy-of select="@class"/>
      <a href="{@Link}">
        <xsl:copy-of select="Name/@loc"/>
        <xsl:value-of select="Name"/>
      </a>
    </li>
  </xsl:template>

  <!-- Pseudo-tab triggering a command -->
  <xsl:template match="Tab[OnClick]" mode="nav" priority="1.25">
    <li>
      <xsl:copy-of select="@class"/>
      <xsl:apply-templates select="OnClick/Command" mode="Tab"/>
      <a>
        <xsl:copy-of select="Name/@loc"/>
        <xsl:value-of select="Name"/>
      </a>
    </li>
  </xsl:template>

  <xsl:template match="Tab">
    <div id="c-pane-{@Id}">
      <xsl:attribute name="class">tab-pane<xsl:if test="@class"><xsl:text> </xsl:text><xsl:value-of select="@class"/></xsl:if></xsl:attribute>
      <xsl:apply-templates select="@*[(local-name(.) != 'Id') and (local-name(.) != 'class')]"/>
      <xsl:apply-templates select="*[local-name(.) != 'Name' and local-name(.) != 'Controller' and local-name(.) != 'Content' and local-name(.) != 'OnClick']"/>
    </div>
  </xsl:template>

  <xsl:template match="Controller" mode="Tab">
    <xsl:attribute name="data-src"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <!-- ****************************************** -->
  <!--                  COMMANDS                  -->
  <!-- ****************************************** -->
  <xsl:template match="Command" mode="Tab">
    <xsl:attribute name="data-command"><xsl:value-of select="Name"/></xsl:attribute>
    <xsl:apply-templates select="Controller" mode="Tab"/>
  </xsl:template>

  <!-- ****************************************** -->
  <!--                  MODALS                    -->
  <!-- ****************************************** -->
  
  <xsl:template match="Modals">
    <xsl:apply-templates select="*"/>
    <div id="c-saving">
      <span class="c-saving" loc="term.saving">Enregistrement en cours...</span>
    </div>
  </xsl:template>
  
  <!-- Modal editor window with associated formular template and command menu
       NOTE that a Modal MUST be completed with ad'hoc Javascript code to hide/show the Modal and to load its content  -->
  <xsl:template match="Modal[Template]">
    <div id="{@Id}-modal" aria-hidden="true" aria-labelledby="label-{@Id}" role="dialog" tabindex="-1" class="modal hide fade">
      <xsl:copy-of select="@*[starts-with(local-name(.), 'data-' )]"/>
      <xsl:apply-templates select="@Width" mode="Modal"/>
      <xsl:apply-templates select="Name" mode="Modal"/>
      <div class="modal-body">
        <xsl:apply-templates select="@Goal" mode="Modal-body"/>
        <div id="{@Id}" data-command="transform" data-template="{Template}">
          <xsl:apply-templates select="@Gap" mode="Modal-editor"/>
          <xsl:apply-templates select="@Goal" mode="Modal-editor"/>
        </div>
      </div>
      <div class="modal-footer c-menu-scope">
        <div id="{@Id}-errors" class="alert alert-error af-validation">
          <button type="button" class="close" data-dismiss="alert">x</button>
        </div>
        <xsl:apply-templates select="Commands/*" mode="Modal"/>
      </div>
    </div>
  </xsl:template>

  <!-- FIXME: move px into Width to align with supergrid.xsl and workflow.xsl -->
  <xsl:template match="@Width" mode="Modal">
    <xsl:attribute name="style">width:<xsl:value-of select="."/>px;margin-left:-<xsl:value-of select=". div 2"/>px</xsl:attribute>
  </xsl:template>

  <!-- Adds a left margin to the modal body, this has been added for instance to leave space 
       for hierarchical drop down lists opening left side (i.e. choice2_position="left") -->
  <xsl:template match="@Gap" mode="Modal-editor">
    <xsl:attribute name="style">margin-left:<xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <xsl:template match="@Goal[. = 'read']" mode="Modal-body">
    <xsl:attribute name="style">background:white</xsl:attribute>
  </xsl:template>

  <xsl:template match="@Goal[. = 'read']" mode="Modal-editor">
    <xsl:attribute name="class">c-display-mode</xsl:attribute>
  </xsl:template>

  <!-- Modal plain window without formular template -->
  <!-- TODO: merge with widgets.xsl / Show ? -->
  <xsl:template match="Modal[not(Template)]">
    <div id="{@Id}-modal" aria-hidden="true" aria-labelledby="label-{@Id}" role="dialog" tabindex="-1" class="modal hide fade">
      <xsl:copy-of select="@*[starts-with(local-name(.), 'data-' )]"/>
      <xsl:apply-templates select="@Width" mode="Modal"/>
      <xsl:apply-templates select="Name" mode="Modal"/>
      <div class="modal-body">
        <xsl:apply-templates select="@Goal" mode="Modal-body"/>
      </div>
      <div class="modal-footer">
        <button class="btn" data-dismiss="modal" aria-hidden="true" loc="action.close">Fermer</button>
      </div>
    </div>
  </xsl:template>

  <xsl:template match="Name" mode="Modal">
    <div class="modal-header">
      <button aria-hidden="true" data-dismiss="modal" class="close" type="button">×</button>
      <h3 id="label-{parent::Modal/@Id}"><xsl:copy-of select="@loc"/><xsl:value-of select="."/></h3>
      <xsl:apply-templates select="parent::Modal/Legend" mode="Modal"/>
    </div>
  </xsl:template>

  <xsl:template match="Legend" mode="Modal">
    <p class="text-info">
      <xsl:copy-of select="@class"/>
      <xsl:copy-of select="text()|*"/>
    </p>
  </xsl:template>

  <!-- Command container on the left hand side -->
  <xsl:template match="LeftSide" mode="Modal">
    <div style="float:left">
      <xsl:apply-templates select="*" mode="Modal"/>
    </div>
  </xsl:template>

  <xsl:template match="Save" mode="Modal">
    <button class="btn btn-primary" data-command="save c-inhibit" data-target="{ancestor::Modal/@Id}" data-save-flags="disableOnSave silentErrors" data-validation-output="{ancestor::Modal/@Id}-errors" data-validation-label="label">
      <xsl:copy-of select="@*[starts-with(local-name(.), 'data-' )]"/>
      <xsl:apply-templates select="Label" mode="Modal"/>
      <xsl:if test="not(Label)">
        <xsl:attribute name="loc">action.save</xsl:attribute>
        Enregistrer
      </xsl:if>
    </button>
  </xsl:template>

  <xsl:template match="Delete" mode="Modal">
    <button class="btn btn-primary" data-command="c-delete c-inhibit" data-target="{ancestor::Modal/@Id}" loc="action.delete">
      <xsl:apply-templates select="Confirm"/>
      Supprimer
    </button>
  </xsl:template>

  <xsl:template match="Close" mode="Modal">
    <button class="btn" data-command="trigger" data-target="{ancestor::Modal/@Id}" data-trigger-event="axel-cancel-edit" loc="action.close">Fermer</button>
  </xsl:template>

  <xsl:template match="Cancel" mode="Modal">
    <button class="btn" data-command="trigger" data-target="{ancestor::Modal/@Id}" data-trigger-event="axel-cancel-edit">
      <xsl:apply-templates select="Label" mode="Modal"/>
      <xsl:if test="not(Label)">
        <xsl:attribute name="loc">action.cancel</xsl:attribute>
        Annuler
      </xsl:if>
    </button>
  </xsl:template>

  <xsl:template match="Clear" mode="Modal">
    <button class="btn" onclick="javascript:$axel('#{ancestor::Modal/@Id}').load('&lt;Reset/>')" loc="action.reset">Effacer</button>
  </xsl:template>

  <xsl:template match="Password" mode="Modal">
    <button class="btn btn-primary" data-command="c-password c-inhibit" data-target="{ancestor::Modal/@Id}"><xsl:value-of select="."/></button>
  </xsl:template>

  <xsl:template match="Button" mode="Modal">
    <button id="{@Id}" class="btn btn-primary"><xsl:copy-of select="@loc"/><xsl:value-of select="@loc"/></button>
  </xsl:template>
  
  <xsl:template match="Label" mode="Modal">
    <xsl:copy-of select="@loc | @style"/>
    <xsl:value-of select="."/>
  </xsl:template>
  
  <!-- ****************************************** -->
  <!--                 FORMULAR                   -->
  <!-- ****************************************** -->

  <xsl:template match="Formular">
    <xsl:call-template name="formular-imp"/>
  </xsl:template>

  <xsl:template match="Formular[parent::Search]">
    <form class="form-horizontal c-search" action="" onsubmit="return false;">
      <xsl:apply-templates select="@Width" mode="Formular"/>
      <xsl:call-template name="formular-imp"/>
    </form>
  </xsl:template>

  <xsl:template match="@Width" mode="Formular">
    <xsl:attribute name="style">width:<xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <xsl:template match="Submission" mode="Formular">
    <xsl:attribute name="data-src"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>
  
  <xsl:template match="Submission" mode="Formular-commands">
    <div class="span5" style="margin: 2px 0 5px 25px">
      <button class="btn btn-small" onclick="$.ajax({{type:'post',url:'{@Controller}/submission',data:$axel('#editor').xml(),dataType:'xml',contentType:'application/xml; charset=UTF-8'}});$('#c-req-ready').hide();return false;" loc="action.save.submission">Sauver filtre par défaut</button>
      <button class="btn btn-small" onclick="$axel('#editor').load('{.}');$('#c-req-ready').show();return false;" loc="action.load.submission">Filtre par défaut</button>
      <button class="btn btn-small" onclick="$axel('#editor').load('&lt;Request/&gt;');$('#c-req-ready').hide();return false;" loc="action.reset">Effacer</button>
    </div>
  </xsl:template>

  <!--Save command inside a Formular -->
  <xsl:template match="Save[ancestor::Formular][not(@Target)]">
    <xsl:call-template name="save-button-imp">
      <xsl:with-param name="target"><xsl:value-of select="ancestor::Formular/@Id"/></xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <!-- ********************** -->
  <!--  Generic commands  -->
  <!-- ********************** -->

  <!--Save acting on a remote explicit Target editor ('save' command) -->
  <xsl:template match="Save[@Target]">
    <xsl:call-template name="save-button-imp">
      <xsl:with-param name="target"><xsl:value-of select="@Target"/></xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <!-- Button-looking navigation link labelled as Cancel
       TODO: implement version for use inside document editor context (triggering axel-cancel-edit event method) -->
  <xsl:template match="Cancel">
    <a class="btn btn-primary btn-small" href="{Action}">
      <xsl:apply-templates select="Label"/>
    </a>
  </xsl:template>

  <!-- Loads empty XML document inside ancestor's Formular editor 
       TODO: implement version for use in other document editor contexts -->
  <xsl:template match="Clear">
    <button class="btn btn-primary btn-small">
      <xsl:if test="ancestor::Formular/@Id">
        <xsl:attribute name="onclick">javascript:$axel('#<xsl:value-of select="ancestor::Formular/@Id" />').load('&lt;Reset/>')</xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="Label"/>
    </button>
  </xsl:template>

  <!-- Button to create an entity ('add' command) with @Target editor's content -->
  <xsl:template match="Create">
    <button data-command="add" data-src="{Controller}" data-edit-action="create" data-target="{@Target}" data-target-modal="{@Target}-modal" class="btn btn-primary btn-small">
      <xsl:apply-templates select="Label"/>
    </button>
  </xsl:template>
  
  <!-- ***************** -->
  <!--  Implementations  -->
  <!-- ***************** -->
  
  <!-- TODO: factorize Resource with other templates ? -->
  <xsl:template name="formular-imp">
    <div data-template="{Template}">
      <xsl:apply-templates select="@Id"/>
      <xsl:copy-of select="@class"/>
      <xsl:if test="Resource">
        <xsl:attribute name="data-src" select="Resource"/>
      </xsl:if>
      <xsl:apply-templates select="Submission" mode="Formular"/>
      <noscript loc="app.message.js">Activez Javascript</noscript>
      <p loc="app.message.loading">Chargement du formulaire en cours</p>
    </div>
    <div class="row">
      <div style="float:right" >
        <xsl:apply-templates select="Commands/*"/>
      </div>
      <xsl:apply-templates select="Submission" mode="Formular-commands"/>
    </div>
  </xsl:template>

  <xsl:template name="save-button-imp">
    <xsl:param name="target"/>
    <button class="btn btn-primary" data-command="save" data-target="{$target}">
      <xsl:if test="not(@data-save-flags)">
        <xsl:attribute name="data-save-flags">disableOnSave</xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="@Id"/>
      <xsl:copy-of select="@onclick"/>
      <xsl:copy-of select="@*[starts-with(local-name(.), 'data-' )]"/>
      <xsl:apply-templates select="Label"/>
    </button>
  </xsl:template>  

</xsl:stylesheet>
