<?xml version="1.0" encoding="UTF-8" ?>
<!--
     XQuery Content Management Library

     Author: Stéphane Sire <s.sire@opppidoc.fr>

     Generates XTiger XML templates with <site:field Key="name"> extension points
     Takes an XML form grid specification as input as found in the formulars folder.

     Dependencies:
     - grid layout based on Boostrap
     - include resources/css/forms.css after Bootstrap
     - form.xql script(s) for <site:field Key="name"> input fields generation
       in every XTiger XML template generation pipeline
     - epilogue site:field function for lazy extension points injection

     NOTE:
     - this is a utility to be run by developers to create the XTiger XML / template / mesh files
     - the companion simulator.xql script can be used to help designing and generating the files

     LIMITATION:
     - Box (select box) to be replaced with extended 'choice' plugin with "appearance=list;layout=vertical"
     - Box currently the Tag must be unique among all Box since it serves to generate component name

     July 2013 - (c) Copyright 2013 Oppidoc SARL. All Rights Reserved.
  -->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xt="http://ns.inria.org/xtiger"
  xmlns:site="http://oppidoc.com/oppidum/site"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  >

  <xsl:template match="/Form">
    <!-- <xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE html>
    </xsl:text> -->
    <html xmlns="http://www.w3.org/1999/xhtml" xmlns:xt="http://ns.inria.org/xtiger" xmlns:site="http://oppidoc.com/oppidum/site" >
    <head><xsl:text>
    </xsl:text><xsl:comment>This template has been generated with "supergrid.xsl" for “<xsl:value-of select="$xslt.goal"/>” purpose</xsl:comment><xsl:text>
    </xsl:text><meta http-equiv="content-type" content="text/html; charset=UTF-8" />

      <title><xsl:value-of select="Title"/></title>

      <!-- ******************************************** -->
      <!-- ********** BEGIN file system test ********** -->
      <!-- ******************************************** -->
      <!-- this is ONLY USEFUL to test the template with AXEL demonstration editor  -->
      <link rel="stylesheet" type="text/css" href="../resources/bootstrap/css/bootstrap.css"/>
      <link rel="stylesheet" type="text/css" href="../resources/css/site.css"/>
       <link rel="stylesheet" type="text/css" href="../resources/css/forms.css"/>
      <!-- ******************************************** -->
      <!-- ********** END file system test ********** -->
      <!-- ******************************************** -->

      <xt:head version="1.1" templateVersion="1.0" label="{@Tag}">

        <xsl:apply-templates select="Verbatim/*"/>

        <xsl:if test="$xslt.goal = 'test'">
          <xt:component name="t_fake_field">
            <xt:use types="choice" values="choice1 choice2 choice3" param="placeholder=test;class=span12 a-control"/>
          </xt:component>

          <xt:component name="t_fake_select_box">
            <ul class="a-select-box">
                <li>
                    <label>Option <input type="checkbox"/>
                    </label>
                </li>
                <li>
                    <label>Option <input type="checkbox"/>
                    </label>
                </li>
                <li>
                    <label>Option <input type="checkbox"/>
                    </label>
                </li>
            </ul>
          </xt:component>
        </xsl:if>

        <xsl:apply-templates select="//Cell[@Tag]|//Cell[not(@Tag) and @TypeName]|//Box" mode="component"/>
        
        <xsl:for-each select="//Include">
          <xsl:if test="not(@src = preceding-sibling::Include/@src)">
            <xsl:apply-templates select="." mode="component"/>
          </xsl:if>
        </xsl:for-each>
        
        <xsl:for-each select="//Embed">
          <xsl:if test="not(@src = preceding-sibling::Embed/@src)">
            <xsl:apply-templates select="." mode="component"/>
          </xsl:if>
        </xsl:for-each>

        <xsl:if test="/Form/Plugins/RichText">
          <!-- //////////////////////////////////// -->
          <!-- /// Start of Rich Text component /// -->
          <!-- //////////////////////////////////// -->

          <xsl:if test="/Form/Plugins/RichText/@Menu[.='static']">
            <xt:component name="t_static_row">
              <div class="t_row ie-select-hack">
                <div class="t_menu">
                  <div class="t_menu_mask">
                    <div class="t_menu_content">
                      <xt:menu-marker target="t_select"/><br/><span class="t_pm"><xt:menu-marker/></span>
                    </div>
                  </div>
                </div>
                <xt:use types="t_parag t_list t_title" label="Parag List Title" param="name=t_select"/>
              </div>
            </xt:component>
          </xsl:if>

          <xsl:if test="/Form/Plugins/RichText/@Menu[.='dynamic']">
            <xt:component name="t_dynamic_row">
              <div class="t_row t_dyn ie-select-hack">
                <div class="t_menu">
                  <div class="t_menu_mask">
                    <div class="t_menu_content">
                      <xt:menu-marker target="t_select"/><br/><xt:menu-marker/>
                    </div>
                  </div>
                </div>
                <xt:use types="t_parag t_list t_title" label="Parag List Title" param="name=t_select"/>
              </div>
            </xt:component>
          </xsl:if>

          <xsl:if test="/Form/Plugins/RichText/@Menu[.='inside']">
            <xt:component name="t_inside_row">
              <div class="t_row t_inside">
                <div class="t_menu">
                  <div class="t_menu_mask">
                    <div class="t_menu_content">
                      <xt:menu-marker target="t_select"/><br/><span class="t_pm"><xt:menu-marker/></span>
                    </div>
                  </div>
                </div>
                <xt:use types="t_parag t_list t_title" label="Parag List Title" param="name=t_select"/>
              </div>
            </xt:component>
          </xsl:if>

          <xt:component name="t_parag" i18n="Parag" i18n-loc="option.parag">
            <p class="x-Parag"><xt:use types="text" param="type=textarea;shape=parent;filter=wiki" loc="content.parag">paragraph</xt:use></p>
          </xt:component>

          <xt:component name="t_list" i18n="List" i18n-loc="option.list">
            <p class="x-ListHeader">
              <xt:use types="text" label="ListHeader" option="unset" loc="content.listHeader">en-tête de liste</xt:use> :
              <span class="t_lstyle"><xt:attribute name="Style" types="text" param="placeholder=empty;filter=style;style_property=list-style-type;style_root_class=t_row;style_target_class=x-List;style_value=decimal" option="unset" default="decimal"/>#.</span>
            </p>
            <ul class="x-List">
              <xt:repeat minOccurs="1" maxOccurs="*" pseudoLabel="Item">
                <!-- <li><xt:use types="text" label="Item" param="type=textarea;shape=parent-80px;filter=wiki" loc="content.listItem">list item</xt:use><xt:menu-marker/></li> -->
                <li class="t_item">
                  <xt:use types="t_item" label="Item"/><span class="tit_menu"><xt:menu-marker/></span><span class="tit_mask"></span>
                </li>
              </xt:repeat>
            </ul>
          </xt:component>

          <xt:component name="t_title" i18n="Titre" i18n-loc="option.title">
            <h3><xt:use types="text" param="shape=parent" loc="content.title">titre</xt:use></h3>
          </xt:component>
          
          <xt:component name="t_item">
            <xt:repeat minOccurs="1" maxOccurs="*" pseudoLabel="Parag">
              <p class="tit_content">
                <xt:use types="text" label="Parag" param="type=textarea;shape=parent-80px;filter=wiki" loc="content.listItem">élément de liste</xt:use>
                <span class="tit_submenu"><xt:menu-marker size="14"/></span>
              </p>
            </xt:repeat>
          </xt:component>

          <!-- ////////////////////////////////// -->
          <!-- /// End of Rich TExt component /// -->
          <!-- ////////////////////////////////// -->
        </xsl:if>

        <xsl:apply-templates select="//Modals/Modal" mode="component"/>

        <!-- Use this component as a main entry point to test this template inside the AXEL editor -->
        <xt:component name="t_simulation">
          <div class="container">
            <xt:use types="t_main"/>
          </div>
        </xt:component>

        <!-- Use this component as the real entry point for this template  -->
        <xt:component name="t_main">
          <xsl:apply-templates select="." mode="main"/>
          <xsl:apply-templates select="Commands/Open" mode="install"/>
        </xt:component>
      </xt:head>
    </head>
    <body>
      <xsl:choose>
        <xsl:when test="$xslt.goal = 'test'">
          <xt:use types="t_main"/>
        </xsl:when>
        <xsl:otherwise>
          <xt:use types="t_main"/>
        </xsl:otherwise>
      </xsl:choose>
    </body>
    </html>
  </xsl:template>

  <!-- Generates template wrapped inside a form element wrapper -->
  <xsl:template match="Form" mode="main">
    <form action="" onsubmit="return false;" tabindex="-1">
      <xsl:apply-templates select="@Orientation | @Width | @Style"/>
      <xsl:apply-templates select="Title[@Render] | Title[@Level]"/>
      <xsl:apply-templates select="site:conditional|Row|Separator|Include"/>
      <xsl:apply-templates select="//Modals/Modal"/>
    </form>
  </xsl:template>

  <!-- Generates template w/o form element wrapper -->
  <xsl:template match="Form[@Wrapper='none'][$xslt.goal != 'test']" priority="1" mode="main">
    <xsl:apply-templates select="@Orientation | @Width | @Style"/>
    <xsl:apply-templates select="Title[@Render] | Title[@Level]"/>
    <xsl:apply-templates select="site:conditional|Row|Separator|Include"/>
    <xsl:apply-templates select="//Modals/Modal"/>
  </xsl:template>

  <xsl:template match="@Style">
      <xsl:attribute name="style"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <xsl:template match="@Orientation">
      <xsl:attribute name="class">form-<xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <!-- While in production the Width shall be set by the form container -->
  <xsl:template match="@Width">
  </xsl:template>

  <xsl:template match="@Width[$xslt.goal='test']">
      <xsl:attribute name="style">width:<xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <!-- Called from Cell when no @Render or @Level
       used by default for instance for plain forms by opposition to document forms  -->
  <xsl:template match="Title">
    <p class="a-cell-legend"><xsl:copy-of select="@loc|@style"/><xsl:value-of select="./text()"/><xsl:apply-templates select="Menu | Hint"/></p>
  </xsl:template>

  <!-- Called from Form (main Title) or Cell -->
  <xsl:template match="Title[@Render]">
    <xsl:element name="{@Render}">
      <xsl:copy-of select="@loc|@style"/>
      <xsl:apply-templates select="@Offset"/>
      <xsl:apply-templates select="*|text()"/>
    </xsl:element>
  </xsl:template>

  <!-- Called from Form (main Title) or Cell -->
  <xsl:template match="Title[@Level]">
    <xsl:variable name="level"><xsl:value-of select="/Form/@StartLevel + @Level - 1"/></xsl:variable>
    <xsl:element name="h{$level}">
      <xsl:copy-of select="@loc|@style"/>
      <xsl:apply-templates select="@Offset"/>
      <xsl:apply-templates select="* | text()"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="Mandatory">
    <span class="sg-mandatory" rel="tooltip" title="{.}"><xsl:copy-of select="@style | @data-placement"/><xsl:apply-templates select="@loc" mode="hint"/>*</span>
  </xsl:template>
  
  <xsl:template match="Hint[not(@Appearance)]">
    <span class="sg-hint" rel="tooltip" title="{.}"><xsl:copy-of select="@style | @data-placement"/><xsl:apply-templates select="@loc" mode="hint"/>?</span>
  </xsl:template>

  <!-- assumes Appearance="mandatory" -->
  <xsl:template match="Hint[@Appearance]">
    <span class="sg-mandatory" rel="tooltip" title="{.}"><xsl:copy-of select="@style | @data-placement"/><xsl:apply-templates select="@loc" mode="hint"/>*</span>
  </xsl:template>

  <xsl:template match="Hint[@meet or @avoid or @flag]" priority="1">
    <site:conditional force="true">
      <xsl:copy-of select="@meet | @avoid | @flag"/>
      <span class="sg-hint" rel="tooltip" title="{.}"><xsl:copy-of select="@style | @data-placement"/><xsl:apply-templates select="@loc" mode="hint"/>?</span>
    </site:conditional>
  </xsl:template>

  <xsl:template match="@loc" mode="hint">
    <xsl:attribute name="title-loc"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <xsl:template match="@Offset">
      <xsl:attribute name="class">a-gap<xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <xsl:template match="@Align">
      <xsl:attribute name="style">text-align:<xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <!-- Imposes a left margin :
       - equals to @L when it is specified
       - equals to 0 when no @W is specified and no @L and no @Offset
       OPTIMIZATION : first case could be avoided when the generated element is the first .span* in a row
   -->
  <xsl:template name="margin-left">
    <xsl:variable name="style"><xsl:if test="@style">;<xsl:value-of select="@style"/></xsl:if></xsl:variable>
    <xsl:apply-templates select="@Id"/>
    <xsl:choose>
      <xsl:when test="@StickyClass"></xsl:when>
      <xsl:when test="@L">
        <xsl:attribute name="style">margin-left:<xsl:value-of select="@L"/><xsl:value-of select="$style"/></xsl:attribute>
      </xsl:when>
      <xsl:when test="not(@W) and not(@Offset)">
        <xsl:attribute name="style">margin-left:0<xsl:value-of select="$style"/></xsl:attribute>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="@style"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="Separator">
    <hr class="a-separator"/>
  </xsl:template>

  <!-- ************* -->
  <!--      Row      -->
  <!-- ************* -->

  <xsl:template match="Row">
    <div class="row-fluid">
      <xsl:copy-of select="@style | @id"/>
      <xsl:apply-templates select="*"/>
    </div>
  </xsl:template>

  <xsl:template match="Row[@Class]">
    <div class="row-fluid {@Class}">
      <xsl:copy-of select="@style | @id"/>
      <xsl:apply-templates select="*"/>
    </div>
  </xsl:template>

  <!-- ************* -->
  <!--    Button     -->
  <!-- ************* -->

  <!-- HTLM class attribute generation -->
  <xsl:template match="Button" mode="class">
    <xsl:variable name="offset"><xsl:if test="@Offset">offset<xsl:value-of select="concat(@Offset,' ')"/></xsl:if></xsl:variable>
    <xsl:variable name="W"><xsl:choose><xsl:when test="@W"><xsl:value-of select="@W"/></xsl:when><xsl:otherwise>12</xsl:otherwise></xsl:choose></xsl:variable>
    <xsl:attribute name="class"><xsl:value-of select="concat($offset,'btn span')"/><xsl:value-of select="$W"/><xsl:text> </xsl:text><xsl:value-of select="@Class"/></xsl:attribute>
  </xsl:template>

  <xsl:template match="Button[@StickyClass]" mode="class">
    <xsl:attribute name="class"><xsl:value-of select="string(@StickyClass)"/></xsl:attribute>
  </xsl:template>
  
  <!-- HTLM class attribute generation -->
  <xsl:template match="Button[parent::Title]" mode="class">
    <xsl:variable name="W"><xsl:choose><xsl:when test="@W"><xsl:value-of select="@W"/></xsl:when><xsl:otherwise>12</xsl:otherwise></xsl:choose></xsl:variable>
    <xsl:attribute name="class">btn <xsl:value-of select="@Class"/></xsl:attribute>
  </xsl:template>

  <xsl:template match="Button">
    <xsl:variable name="key"><xsl:value-of select="@Key"/></xsl:variable>
    <button type="button">
      <xsl:apply-templates select="." mode="class"/>
      <xsl:call-template name="margin-left"/>
      <xsl:copy-of select="@id | @loc | @style"/>
      <xsl:apply-templates select="/Form/Commands/*[contains(@Key, $key)]">
        <xsl:with-param name="key"><xsl:value-of select="$key"/></xsl:with-param>
      </xsl:apply-templates>
      <xsl:value-of select="."/>
    </button>
  </xsl:template>

  <xsl:template match="Button" mode="MenuBar">
    <xsl:variable name="key"><xsl:value-of select="@Key"/></xsl:variable>
    <xsl:variable name="W"><xsl:choose><xsl:when test="@W"><xsl:value-of select="@W"/></xsl:when><xsl:otherwise>12</xsl:otherwise></xsl:choose></xsl:variable>
    <button class="btn span{$W} {@Class}" type="button">
      <xsl:call-template name="margin-left"/>
      <xsl:copy-of select="@loc | @style"/>
      <xsl:apply-templates select="/Form/Commands/*[contains(@Key, $key)]">
        <xsl:with-param name="key"><xsl:value-of select="$key"/></xsl:with-param>
      </xsl:apply-templates>
      <xsl:value-of select="."/>
    </button>
  </xsl:template>  

  <!-- In production Button generation can be controlled with Avoid / Meet rules
       Currently the rules are tested against the goal parameter of the template URL -->
  <xsl:template match="Button[$xslt.goal = 'save']">
    <xsl:variable name="key"><xsl:value-of select="@Key"/></xsl:variable>
    <xsl:variable name="W"><xsl:choose><xsl:when test="@W"><xsl:value-of select="@W"/></xsl:when><xsl:otherwise>12</xsl:otherwise></xsl:choose></xsl:variable>
    <site:field filter="copy" force="true">
      <xsl:apply-templates select="@Avoid | @Meet"/>
      <button type="button">
         <xsl:apply-templates select="." mode="class"/>
        <xsl:copy-of select="@id | @loc | @style"/>
        <xsl:call-template name="margin-left"/>
        <xsl:apply-templates select="/Form/Commands/*[contains(@Key, $key)]">
          <xsl:with-param name="key"><xsl:value-of select="$key"/></xsl:with-param>
        </xsl:apply-templates>
        <xsl:value-of select="."/>
      </button>
    </site:field>
  </xsl:template>

  <!-- ******* -->
  <!--  Menu   -->
  <!-- ******* -->

  <xsl:template match="MenuBar">
    <xsl:variable name="W"><xsl:choose><xsl:when test="@W"><xsl:value-of select="@W"/></xsl:when><xsl:otherwise>12</xsl:otherwise></xsl:choose></xsl:variable>
    <xsl:variable name="offset"><xsl:if test="@Offset">offset<xsl:value-of select="concat(@Offset,' ')"/></xsl:if></xsl:variable>
    <xsl:variable name="class"><xsl:if test="@Class"><xsl:text> </xsl:text><xsl:value-of select="@Class"/></xsl:if></xsl:variable>
    <xsl:variable name="gap"><xsl:if test="floor(@Gap) = @Gap"><xsl:value-of select="@Gap"/></xsl:if></xsl:variable>
    <div class="{$offset}span{$W}{$class}">
      <xsl:apply-templates select="Button"/>
    </div>
  </xsl:template>
  
  <xsl:template match="MenuBar[$xslt.goal = 'save']">
    <xsl:variable name="W"><xsl:choose><xsl:when test="@W"><xsl:value-of select="@W"/></xsl:when><xsl:otherwise>12</xsl:otherwise></xsl:choose></xsl:variable>
    <xsl:variable name="offset"><xsl:if test="@Offset">offset<xsl:value-of select="concat(@Offset,' ')"/></xsl:if></xsl:variable>
    <xsl:variable name="class"><xsl:if test="@Class"><xsl:text> </xsl:text><xsl:value-of select="@Class"/></xsl:if></xsl:variable>
    <xsl:variable name="gap"><xsl:if test="floor(@Gap) = @Gap"><xsl:value-of select="@Gap"/></xsl:if></xsl:variable>
    <site:field filter="copy" force="true">
      <xsl:apply-templates select="@Avoid | @Meet"/>
      <div class="{$offset}span{$W}{$class}">
        <xsl:apply-templates select="Button" mode="MenuBar"/>
      </div>
    </site:field>
  </xsl:template>

  <xsl:template match="@Avoid">
    <xsl:attribute name="avoid"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <xsl:template match="@Meet">
    <xsl:attribute name="meet"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>  

  <!-- ************* -->
  <!--     Hide      -->
  <!-- ************* -->
  <xsl:template match="Hide">
    <span style="display:none">
      <xsl:apply-templates select="@Class"/>
      <site:field force="true">
        <xsl:copy-of select="@Key"/>
        <xsl:copy-of select="@Tag"/>
      </site:field>
    </span>
  </xsl:template>

  <!-- ************* -->
  <!--     Field     -->
  <!-- ************* -->

  <!--  Supergrid simulator TEST generation
        Generates with a fake <select> input field for testing or with the final plugin if it is defined -->
  <xsl:template match="Field[. != ''][$xslt.goal != 'save']">
    <xsl:variable name="key"><xsl:value-of select="@Key"/></xsl:variable>
    <xsl:variable name="tag"><xsl:value-of select="@Tag"/></xsl:variable>
    <xsl:variable name="offset"><xsl:if test="@Offset">offset<xsl:value-of select="concat(@Offset,' ')"/></xsl:if></xsl:variable>
    <xsl:variable name="W"><xsl:choose><xsl:when test="@W"><xsl:value-of select="@W"/></xsl:when><xsl:otherwise>12</xsl:otherwise></xsl:choose></xsl:variable>
    <xsl:variable name="gap"><xsl:if test="floor(@Gap) = @Gap"><xsl:value-of select="@Gap"/></xsl:if></xsl:variable>
    <xsl:variable name="align"><xsl:if test="@Align">;text-align:<xsl:value-of select="@Align"/></xsl:if></xsl:variable>
    <div class="{$offset}span{$W}">
      <xsl:call-template name="margin-left"/>
      <div class="control-group">
        <xsl:apply-templates select="/Form/Plugins/RichText[contains(@Keys, $key)]" mode="pre">
            <xsl:with-param name="key"><xsl:value-of select="$key"/></xsl:with-param>
        </xsl:apply-templates>
        <xsl:apply-templates select="/Form/Bindings/Enforce/*[contains(@Keys, $key)]" mode="pre">
            <xsl:with-param name="key"><xsl:value-of select="$key"/></xsl:with-param>
        </xsl:apply-templates>
        <label class="control-label a-gap{$gap}">
          <xsl:copy-of select="@loc"/>
            <xsl:if test="$gap = ''">
              <xsl:attribute name="style"><xsl:value-of select="concat(concat(concat('width:', @Gap * 60),'px'), $align)"/></xsl:attribute>
            </xsl:if>
          <xsl:value-of select="."/>            
          <xsl:apply-templates select="/Form/Hints/Mandatory[contains(@Tags, $tag) or contains(@Keys, $key)]"/>
          <xsl:apply-templates select="/Form/Hints/Hint[contains(@Keys, $key)]"/>
        </label>
        <div class="controls">
          <xsl:apply-templates select="@Class"/>
          <xsl:apply-templates select="/Form/Hints/Mandatory[contains(@Tags, $tag) or contains(@Keys, $key)]" mode="pre">
            <xsl:with-param name="key"><xsl:value-of select="$key"/></xsl:with-param>
          </xsl:apply-templates>
          <xsl:if test="$gap = ''">
            <xsl:attribute name="style"><xsl:value-of select="concat(concat('margin-left:', @Gap * 60 + 20),'px')"/></xsl:attribute>
          </xsl:if>
          <xsl:apply-templates select="/Form/Bindings/*[local-name(.) != 'Require' and local-name(.) != 'Enforce' and contains(@Keys, $key)]">
            <xsl:with-param name="key"><xsl:value-of select="$key"/></xsl:with-param>
          </xsl:apply-templates>
          <xsl:choose>
            <xsl:when test="/Form/Plugins/*[contains(@Keys, $key) or (@Prefix and starts-with($key, @Prefix))]">
              <xsl:apply-templates select="/Form/Plugins/*[contains(@Keys, $key) or (@Prefix and starts-with($key, @Prefix))]">
                <xsl:with-param name="key"><xsl:value-of select="$key"/></xsl:with-param>
                <xsl:with-param name="tag"><xsl:value-of select="$tag"/></xsl:with-param>
              </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
              <xt:use types="t_fake_field" label="{@Tag}"/>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:apply-templates select="/Form/Bindings/Enforce/*[contains(@Keys, $key)]" mode="post">
              <xsl:with-param name="key"><xsl:value-of select="$key"/></xsl:with-param>
          </xsl:apply-templates>
        </div>
      </div>
    </div><xsl:comment>/span</xsl:comment>
  </xsl:template>

  <!--  Supergrid SAVE generation
        Generates with Oppidum mesh conventional extension point for input field or with the final plugin if it is defined -->
  <xsl:template match="Field[. != ''][$xslt.goal = 'save']">
    <xsl:variable name="key"><xsl:value-of select="@Key"/></xsl:variable>
    <xsl:variable name="tag"><xsl:value-of select="@Tag"/></xsl:variable>
    <xsl:variable name="offset"><xsl:if test="@Offset">offset<xsl:value-of select="concat(@Offset,' ')"/></xsl:if></xsl:variable>
    <xsl:variable name="W"><xsl:choose><xsl:when test="@W"><xsl:value-of select="@W"/></xsl:when><xsl:otherwise>12</xsl:otherwise></xsl:choose></xsl:variable>
    <xsl:variable name="gap"><xsl:if test="floor(@Gap) = @Gap"><xsl:value-of select="@Gap"/></xsl:if></xsl:variable>
    <xsl:variable name="align"><xsl:if test="@Align">;text-align:<xsl:value-of select="@Align"/></xsl:if></xsl:variable>
    <div class="{$offset}span{$W}">
      <xsl:call-template name="margin-left"/>
      <div class="control-group">
        <xsl:apply-templates select="/Form/Bindings/Enforce/*[contains(@Keys, $key)]" mode="pre">
            <xsl:with-param name="key"><xsl:value-of select="$key"/></xsl:with-param>
        </xsl:apply-templates>
        <xsl:apply-templates select="/Form/Plugins/RichText[contains(@Keys, $key)]" mode="pre">
            <xsl:with-param name="key"><xsl:value-of select="$key"/></xsl:with-param>
        </xsl:apply-templates>
        <label class="control-label a-gap{$gap}">
          <xsl:copy-of select="@loc"/>
          <xsl:if test="$gap = ''">
            <xsl:attribute name="style"><xsl:value-of select="concat(concat(concat('width:', @Gap * 60),'px'), $align)"/></xsl:attribute>
          </xsl:if>
          <xsl:value-of select="."/>
          <xsl:apply-templates select="/Form/Hints/Mandatory[contains(@Tags, $tag) or contains(@Keys, $key)]">
            <xsl:with-param name="key"><xsl:value-of select="$key"/></xsl:with-param>
          </xsl:apply-templates>
          <xsl:apply-templates select="/Form/Hints/Hint[contains(@Keys, $key)]"/>
        </label>
        <div class="controls">
          <xsl:apply-templates select="@Class"/>
          <xsl:apply-templates select="/Form/Hints/Mandatory[contains(@Tags, $tag) or contains(@Keys, $key)]" mode="pre">
            <xsl:with-param name="key"><xsl:value-of select="$key"/></xsl:with-param>
          </xsl:apply-templates>
          <xsl:if test="$gap = ''">
            <xsl:attribute name="style"><xsl:value-of select="concat(concat('margin-left:', @Gap * 60 + 20),'px')"/></xsl:attribute>
          </xsl:if>
          <xsl:apply-templates select="/Form/Bindings/*[local-name(.) != 'Require' and local-name(.) != 'Enforce' and contains(@Keys, $key)]">
            <xsl:with-param name="key"><xsl:value-of select="$key"/></xsl:with-param>
          </xsl:apply-templates>
          <xsl:choose>
            <xsl:when test="/Form/Plugins/*[@Filter = 'no'][contains(@Keys, $key) or (@Prefix and starts-with($key, @Prefix))]">
              <xsl:apply-templates select="/Form/Plugins/*[contains(@Keys, $key) or (@Prefix and starts-with($key, @Prefix))]">
                  <xsl:with-param name="key"><xsl:value-of select="$key"/></xsl:with-param>
              </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="/Form/Plugins/*[contains(@Keys, $key) or (@Prefix and starts-with($key, @Prefix))]">
              <site:field filter="copy" force="true">
                <xsl:apply-templates select="/Form/Plugins/*[contains(@Keys, $key) or (@Prefix and starts-with($key, @Prefix))]">
                    <xsl:with-param name="key"><xsl:value-of select="$key"/></xsl:with-param>
                </xsl:apply-templates>
              </site:field>
            </xsl:when>
            <xsl:otherwise>
              <site:field Size="{number($W) - number(@Gap)}" force="true">
                <xsl:copy-of select="@Key | @Tag | @Placeholder-loc"/>
                <xsl:if test="/Form/Bindings/Enforce/*[contains(@Keys, $key)] or /Form/Hints/Mandatory[not(@Feedback) or @Feedback != 'none'][contains(@Tags, $tag) or contains(@Keys, $key)]">
                  <xsl:attribute name="Filter">event</xsl:attribute>
                </xsl:if>
                <xsl:if test="/Form/Bindings/Require[contains(@Keys, $key)]">
                  <xsl:attribute name="Required">true</xsl:attribute>
                </xsl:if>
                <xsl:value-of select="@Key"/>[<xsl:value-of select="@Tag"/>,<xsl:value-of select="number(@W) - number(@Gap)"/>]
              </site:field>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:apply-templates select="/Form/Bindings/Enforce/*[contains(@Keys, $key)]" mode="post">
              <xsl:with-param name="key"><xsl:value-of select="$key"/></xsl:with-param>
          </xsl:apply-templates>
        </div>
      </div>
    </div><xsl:comment>/span</xsl:comment>
  </xsl:template>

  <!--  Fake unlabelled Field - 
        Note that there is a special handling of RichText and Input with @Append plugins 
        because they need to be adapted inside the epilogue using a signature attribute...
        FIXME: an improvement could be to generate the outer div iff there are some contraints set 
        on the field through Enforce or Require (because they generate micro-format attributes 
        that need to be attached somewhere)
       -->
  <xsl:template match="Field[. = ''][$xslt.goal != 'save']">
    <xsl:variable name="key"><xsl:value-of select="@Key"/></xsl:variable>
    <xsl:variable name="pos"><xsl:value-of select="count(preceding::Field[string(@Key) = $key])"/></xsl:variable>
    <div>
      <xsl:choose>
        <xsl:when test="@W"><xsl:attribute name="class">span<xsl:value-of select="@W"/></xsl:attribute></xsl:when>
        <xsl:otherwise></xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="/Form/Bindings/Enforce/*[contains(@Keys, $key)]" mode="pre">
          <xsl:with-param name="key"><xsl:value-of select="$key"/></xsl:with-param>
      </xsl:apply-templates>
      <xsl:if test="@Validation">
        <label style="display:none"><xsl:value-of select="string(@Validation)"/></label>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="/Form/Plugins/*[contains(@Keys, $key) or (@Prefix and starts-with($key, @Prefix))]">
          <xsl:choose>
            <xsl:when test="/Form/Plugins/RichText[contains(@Keys, $key)] or /Form/Plugins/Input[@Append][contains(@Keys, $key)]">
              <site:field filter="copy" force="true">
                <xsl:apply-templates select="/Form/Plugins/*[contains(@Keys, $key) or (@Prefix and starts-with($key, @Prefix))]">
                    <xsl:with-param name="key"><xsl:value-of select="$key"/></xsl:with-param>
                </xsl:apply-templates>
              </site:field>
            </xsl:when>
            <xsl:when test="/Form/Plugins/*[@Filter = 'no'][contains(@Keys, $key) or (@Prefix and starts-with($key, @Prefix))]">
              <xsl:apply-templates select="/Form/Plugins/*[contains(@Keys, $key) or (@Prefix and starts-with($key, @Prefix))]">
                  <xsl:with-param name="key"><xsl:value-of select="$key"/></xsl:with-param>
              </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="/Form/Plugins/*[contains(@Keys, $key) or (@Prefix and starts-with($key, @Prefix))]">
                    <xsl:with-param name="key"><xsl:value-of select="$key"/></xsl:with-param>
                    <xsl:with-param name="pos"><xsl:value-of select="$pos"/></xsl:with-param>
                </xsl:apply-templates>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:choose>
            <xsl:when test="$xslt.goal = 'save'">
              <site:field force="true">
                <xsl:copy-of select="@Key | @Tag | @Placeholder-loc"/>
                <xsl:if test="/Form/Bindings/Enforce/*[contains(@Keys, $key)]">
                  <xsl:attribute name="Filter">event</xsl:attribute>
                </xsl:if>
                <xsl:if test="/Form/Bindings/Require[contains(@Keys, $key)]">
                  <xsl:attribute name="Required">true</xsl:attribute>
                </xsl:if>
                <xsl:value-of select="@Key"/>[<xsl:value-of select="@Tag"/>,<xsl:value-of select="number(@W) - number(@Gap)"/>]
              </site:field>
            </xsl:when>
            <xsl:otherwise>
              <xt:use types="t_fake_field" label="{@Tag}"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="/Form/Bindings/Enforce/*[contains(@Keys, $key)]" mode="post">
          <xsl:with-param name="key"><xsl:value-of select="$key"/></xsl:with-param>
      </xsl:apply-templates>
    </div>
  </xsl:template>
  
  <xsl:template match="Field[. = ''][$xslt.goal = 'save']">
    <xsl:variable name="key"><xsl:value-of select="@Key"/></xsl:variable>
    <xsl:variable name="pos"><xsl:value-of select="count(./preceding::Field[string(@Key) = $key])"/></xsl:variable>
    <div>
      <xsl:choose>
        <xsl:when test="@W"><xsl:attribute name="class">span<xsl:value-of select="@W"/></xsl:attribute></xsl:when>
        <xsl:otherwise></xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="/Form/Bindings/Enforce/*[contains(@Keys, $key)]" mode="pre">
          <xsl:with-param name="key"><xsl:value-of select="$key"/></xsl:with-param>
      </xsl:apply-templates>
      <xsl:if test="@Validation">
        <label style="display:none"><xsl:value-of select="string(@Validation)"/></label>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="/Form/Plugins/*[contains(@Keys, $key) or (@Prefix and starts-with($key, @Prefix))]">
          <xsl:choose>
            <xsl:when test="/Form/Plugins/RichText[contains(@Keys, $key)] or /Form/Plugins/Input[@Append][contains(@Keys, $key)]">
              <site:field filter="copy" force="true">
                <xsl:apply-templates select="/Form/Plugins/*[contains(@Keys, $key) or (@Prefix and starts-with($key, @Prefix))]">
                    <xsl:with-param name="key"><xsl:value-of select="$key"/></xsl:with-param>
                </xsl:apply-templates>
              </site:field>
            </xsl:when>
            <xsl:when test="/Form/Plugins/*[@Filter = 'no'][contains(@Keys, $key) or (@Prefix and starts-with($key, @Prefix))]">
              <xsl:apply-templates select="/Form/Plugins/*[contains(@Keys, $key) or (@Prefix and starts-with($key, @Prefix))]">
                  <xsl:with-param name="key"><xsl:value-of select="$key"/></xsl:with-param>
              </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
              <site:field filter="copy" force="true">
                <xsl:apply-templates select="/Form/Plugins/*[contains(@Keys, $key) or (@Prefix and starts-with($key, @Prefix))]">
                    <xsl:with-param name="key"><xsl:value-of select="$key"/></xsl:with-param>
                    <xsl:with-param name="pos"><xsl:value-of select="$pos"/></xsl:with-param>
                </xsl:apply-templates>
              </site:field>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:choose>
            <xsl:when test="$xslt.goal = 'save'">
              <site:field force="true">
                <xsl:copy-of select="@Key | @Tag | @Placeholder-loc"/>
                <xsl:if test="/Form/Bindings/Enforce/*[contains(@Keys, $key)]">
                  <xsl:attribute name="Filter">event</xsl:attribute>
                </xsl:if>
                <xsl:if test="/Form/Bindings/Require[contains(@Keys, $key)]">
                  <xsl:attribute name="Required">true</xsl:attribute>
                </xsl:if>
                <xsl:value-of select="@Key"/>[<xsl:value-of select="@Tag"/>,<xsl:value-of select="number(@W) - number(@Gap)"/>]
              </site:field>
            </xsl:when>
            <xsl:otherwise>
              <xt:use types="t_fake_field" label="{@Tag}"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="/Form/Bindings/Enforce/*[contains(@Keys, $key)]" mode="post">
          <xsl:with-param name="key"><xsl:value-of select="$key"/></xsl:with-param>
      </xsl:apply-templates>
    </div>
  </xsl:template>  

  <xsl:template match="@Class">
    <xsl:attribute name="class">controls <xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <!-- ************* -->
  <!--     Cell      -->
  <!-- ************* -->

  <!-- Standard Cell with a gutter implemented as two customs div.a-cell-label and div.a-cell-body inside a Bootstrap cell -->
  <xsl:template match="Cell">
    <xsl:variable name="W"><xsl:choose><xsl:when test="@W"><xsl:value-of select="@W"/></xsl:when><xsl:otherwise>12</xsl:otherwise></xsl:choose></xsl:variable>
    <xsl:variable name="offset"><xsl:if test="@Offset">offset<xsl:value-of select="concat(@Offset,' ')"/></xsl:if></xsl:variable>
    <xsl:variable name="class"><xsl:if test="@Class"><xsl:text> </xsl:text><xsl:value-of select="@Class"/></xsl:if></xsl:variable>
    <xsl:variable name="gap"><xsl:if test="floor(@Gap) = @Gap"><xsl:value-of select="@Gap"/></xsl:if></xsl:variable>
    <div class="{$offset}span{$W}{$class}">
      <xsl:call-template name="margin-left"/>
      <div class="a-cell-label a-gap{$gap}">
        <xsl:if test="$gap = ''">
          <xsl:attribute name="style"><xsl:value-of select="concat(concat('width:', @Gap * 60),'px')"/></xsl:attribute>
        </xsl:if>
        <xsl:apply-templates select="Title[1] | SideLink"/>
      </div>
      <div class="a-cell-body">
        <xsl:if test="$gap = ''">
          <xsl:attribute name="style"><xsl:value-of select="concat(concat('margin-left:', @Gap * 60 + 20),'px')"/></xsl:attribute>
        </xsl:if>
        <xsl:apply-templates select="*[(local-name(.) != 'Title') and (local-name(.) != 'SideLink')] | Title[position() > 1]"/>
      </div>
    </div>
  </xsl:template>

  <!-- Simple Cell without a gutter implemented as a single Bootstrap cell -->
  <xsl:template match="Cell[not(@Gap) and not(@Tag)]">
    <xsl:variable name="W"><xsl:choose><xsl:when test="@W"><xsl:value-of select="@W"/></xsl:when><xsl:otherwise>12</xsl:otherwise></xsl:choose></xsl:variable>
    <xsl:variable name="offset"><xsl:if test="@Offset">offset<xsl:value-of select="concat(@Offset,' ')"/></xsl:if></xsl:variable>
    <xsl:variable name="class"><xsl:if test="@Class"><xsl:text> </xsl:text><xsl:value-of select="@Class"/></xsl:if></xsl:variable>
    <div class="{$offset}span{$W}{$class}">
       <xsl:call-template name="margin-left"/>
       <xsl:apply-templates select="*"/>
    </div>
  </xsl:template>

  <!-- xt:use insertion of any type of Cell with a Tag -->
  <xsl:template match="Cell[@Tag]">
    <xsl:variable name="type">
      <xsl:choose>
        <xsl:when test="@TypeName"><xsl:value-of select="@TypeName"/></xsl:when>
        <xsl:when test="@Type"><xsl:value-of select="@Type"/></xsl:when>
        <xsl:otherwise><xsl:value-of select="@Tag"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xt:use types="t_{$type}">
      <xsl:if test="@Tag"><xsl:attribute name="label"><xsl:value-of select="@Tag"/></xsl:attribute></xsl:if>
    </xt:use>
  </xsl:template>

  <!-- xt:use insertion of a Cell previously declared with a Tag or a TypeName
       Copy cat from match="Cell[@Tag]" rule  -->
  <xsl:template match="Use">
    <xsl:variable name="type">
      <xsl:choose>
        <xsl:when test="@TypeName"><xsl:value-of select="@TypeName"/></xsl:when>
        <xsl:when test="@Type"><xsl:value-of select="@Type"/></xsl:when>
        <xsl:otherwise><xsl:value-of select="@Tag"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xt:use types="t_{$type}">
      <xsl:if test="@Tag"><xsl:attribute name="label"><xsl:value-of select="@Tag"/></xsl:attribute></xsl:if>
    </xt:use>
  </xsl:template>

  <!-- Copy cat from match="Cell" rule
       We cannot just call apply-templates on "." because of "Cell[@Tag]" rule -->
  <xsl:template match="Cell" mode="component">
    <xsl:variable name="W"><xsl:choose><xsl:when test="@W"><xsl:value-of select="@W"/></xsl:when><xsl:otherwise>12</xsl:otherwise></xsl:choose></xsl:variable>
    <xsl:variable name="offset"><xsl:if test="@Offset">offset<xsl:value-of select="concat(@Offset,' ')"/></xsl:if></xsl:variable>
    <xsl:variable name="type"><xsl:choose><xsl:when test="@TypeName"><xsl:value-of select="@TypeName"/></xsl:when><xsl:otherwise><xsl:value-of select="@Tag"/></xsl:otherwise></xsl:choose></xsl:variable>
    <xsl:variable name="class"><xsl:if test="@Class"><xsl:text> </xsl:text><xsl:value-of select="@Class"/></xsl:if></xsl:variable>
    <xsl:variable name="gap"><xsl:if test="floor(@Gap) = @Gap"><xsl:value-of select="@Gap"/></xsl:if></xsl:variable>
    <xt:component name="t_{$type}">
      <div class="{$offset}span{$W}{$class}">
        <xsl:call-template name="margin-left"/>
        <div class="a-cell-label a-gap{$gap}">
          <xsl:if test="$gap = ''">
            <xsl:attribute name="style"><xsl:value-of select="concat(concat('width:', @Gap * 60),'px')"/></xsl:attribute>
          </xsl:if>
          <xsl:apply-templates select="Title[1] | SideLink"/>
        </div>
        <div class="a-cell-body">
          <xsl:if test="$gap = ''">
            <xsl:attribute name="style"><xsl:value-of select="concat(concat('margin-left:', @Gap * 60 + 20),'px')"/></xsl:attribute>
          </xsl:if>
          <xsl:apply-templates select="*[(local-name(.) != 'Title') and (local-name(.) != 'SideLink')] | Title[position() > 1]"/>
        </div>
      </div>
    </xt:component>
  </xsl:template>

  <!-- Copy cat from match="Cell[not(@Gap)]" rule
       We cannot just call apply-templates on "." because of "Cell[@Tag]" rule -->
  <xsl:template match="Cell[not(@Gap)]" mode="component">
    <xsl:variable name="W"><xsl:choose><xsl:when test="@W"><xsl:value-of select="@W"/></xsl:when><xsl:otherwise>12</xsl:otherwise></xsl:choose></xsl:variable>
    <xsl:variable name="offset"><xsl:if test="@Offset">offset<xsl:value-of select="concat(@Offset,' ')"/></xsl:if></xsl:variable>
    <xsl:variable name="type"><xsl:choose><xsl:when test="@TypeName"><xsl:value-of select="@TypeName"/></xsl:when><xsl:otherwise><xsl:value-of select="@Tag"/></xsl:otherwise></xsl:choose></xsl:variable>
    <xsl:variable name="class"><xsl:if test="@Class"><xsl:text> </xsl:text><xsl:value-of select="@Class"/></xsl:if></xsl:variable>
    <xt:component name="t_{$type}">
      <div class="{$offset}span{$W}{$class}">
         <xsl:call-template name="margin-left"/>
         <xsl:apply-templates select="*"/>
      </div>
    </xt:component>
  </xsl:template>
  
  <xsl:template match="SideLink">
    Download <a href="{$xslt.base-url}{substring-after(@Path, '/')}" target="_blank"><xsl:value-of select="."/></a>
  </xsl:template>

  <!-- TODO: @NoTarget='1' only, implement not(@NoTarget) -->
  <xsl:template match="SideLink[@Appearance = 'compact']">
    <a href="{$xslt.base-url}{substring-after(@Path, '/')}" class="btn btn-primary">Download</a>
  </xsl:template>

  <!-- ************* -->
  <!--     Box       -->
  <!-- ************* -->

  <!-- Generates for testing -->
  <xsl:template match="Box">
    <xt:use types="t_{@Tag}_box" label="{@Tag}"/>
  </xsl:template>

  <!-- Generates for testing -->
  <xsl:template match="Box" mode="component">
    <xt:component name="t_{@Tag}_box">
      <div class="span{@W}">
        <xsl:call-template name="margin-left"/>        
        <fieldgroup class="a-select-box">
          <legend><xsl:copy-of select="Title/@loc"/><xsl:value-of select="Title/text()"/> <xsl:apply-templates select="Title/Hint"/></legend>
          <xt:use types="t_fake_select_box" label="Name"/>
        </fieldgroup>
      </div>
    </xt:component>
  </xsl:template>

  <!-- Generates with Oppidum mesh conventional extension point for input field -->
  <!-- FIXME: GENERER un xt:component pour chaque BOX avec son TAG ou sinon faire types="choice" param="appearance=list" -->
  <xsl:template match="Box[$xslt.goal = 'save']">
    <xt:use types="t_{@Tag}_box" label="{@Tag}"/>
  </xsl:template>

  <!-- Generates with Oppidum mesh conventional extension point for input field -->
  <!-- FIXME: GENERER un xt:component pour chaque BOX avec son TAG ou sinon faire types="choice" param="appearance=list" -->
  <xsl:template match="Box[$xslt.goal = 'save']" mode="component">
    <xt:component name="t_{@Tag}_box">
      <div class="span{@W}">
        <xsl:call-template name="margin-left"/>        
        <fieldgroup class="a-select-box">
          <legend><xsl:copy-of select="Title/@loc"/><xsl:value-of select="Title/text()"/> <xsl:apply-templates select="Title/Hint"/></legend>
          <site:field Key="{@Key}" Tag="{@Tag}" force="true">
            <xsl:value-of select="@Key"/>[<xsl:value-of select="@Tag"/>]
          </site:field>
        </fieldgroup>
      </div>
    </xt:component>
  </xsl:template>

  <!-- ************* -->
  <!--     Repeat    -->
  <!-- ************* -->

  <xsl:template match="Repeat">
    <table class="a-repeat-table">
      <xsl:apply-templates select="@Id"/>
      <xt:repeat label="{@Tag}" minOccurs="{@Min}" maxOccurs="*">
        <tr>
          <td class="a-repeat-row">
            <xsl:apply-templates select="*" />
          </td>
        </tr>
      </xt:repeat>
    </table>
  </xsl:template>

  <!-- Same as above but with computed pseudoLabel instead of lab  -->
  <xsl:template match="Repeat[not(@Tag)]">
    <table class="a-repeat-table">
      <xsl:apply-templates select="@Id"/>
      <xt:repeat pseudoLabel="{.//@Tag[1]}" minOccurs="{@Min}" maxOccurs="*">
        <tr>
          <td class="a-repeat-row">
            <xsl:apply-templates select="*" />
          </td>
        </tr>
      </xt:repeat>
    </table>
  </xsl:template>

  <xsl:template match="Optional">
    <xt:repeat label="{@Tag}" minOccurs="0" maxOccurs="1">
      <xsl:apply-templates select="*"/>
    </xt:repeat>
  </xsl:template>

  <xsl:template match="Menu"><xt:menu-marker/>
  </xsl:template>

  <xsl:template match="xhtml:Menu"><xt:menu-marker/>
  </xsl:template>

  <!-- ************* -->
  <!--     Photo     -->
  <!-- ************* -->

  <!-- FIXME: insert $xslt.base-url iff absolute path
       - note currently handles only an absolute path
       -->
  <xsl:template match="Photo">
    <xt:use types="photo" label="{@Tag}"
      param="photo_URL={$xslt.base-url}{substring-after(@Controller,'/')};photo_base={$xslt.base-url}{substring-after(@Base,'/')};display=above;trigger=click;class=img-polaroid"/>
  </xsl:template>

  <!-- *************** -->
  <!--     Constant    -->
  <!-- *************** -->

  <!-- FIXME: insert $xslt.base-url iff absolute path
       - note currently handles only an absolute path
       FIXME: hard coded project name (coaching) in noimage parameter generation
       -->
  <xsl:template match="Constant[@Media='image']">
    <xt:use types="constant" label="{@Tag}"
      param="constant_media=image;image_base={$xslt.base-url}{substring-after(@Base,'/')};noimage={$xslt.base-url}static/{$xslt.app-name}/images/identity.png;class=img-polaroid"/>
  </xsl:template>

  <!-- ************************* -->
  <!--    Model for form.xql     -->
  <!-- ************************* -->

  <xsl:template match="/Form[$xslt.goal = 'model']">
    <site:view>
      <xsl:apply-templates select="//Field" mode="model"/>
      <xsl:apply-templates select="//Box" mode="model"/>
    </site:view>
  </xsl:template>

  <xsl:template match="Field" mode="model">
    <xsl:variable name="key"><xsl:value-of select="@Key"/></xsl:variable>
    <xsl:if test="not(/Form/Plugins/*[contains(@Keys, $key)])">
      <site:field Key="{@Key}" force="true">
        { form:gen-unfinished-selector($lang, "") }
      </site:field>
    </xsl:if>
  </xsl:template>

  <xsl:template match="Box" mode="model">
    <site:field Key="{@Key}" filter="no" force="true">
    { local:gen-select-box(('choice', 'xxxx')) }
    </site:field>
  </xsl:template>

  <!-- ************************* -->
  <!--         Bindings          -->
  <!-- ************************* -->
  
  <xsl:template match="RegExp" mode="pre">
    <xsl:param name="key">key</xsl:param>
    <xsl:attribute name="data-binding">regexp</xsl:attribute>
    <xsl:attribute name="data-regexp"><xsl:value-of select="."/></xsl:attribute>
    <xsl:attribute name="data-variable"><xsl:value-of select="$key"/></xsl:attribute>
    <xsl:attribute name="data-error-scope">div.control-group</xsl:attribute>
    <xsl:apply-templates select="@Pattern"/>
  </xsl:template>

  <xsl:template match="RegExp" mode="post">
    <xsl:param name="key">key</xsl:param>
    <p class="af-error" data-regexp-error="{$key}"><xsl:apply-templates select="@Message-loc"/><xsl:value-of select="@Message"/></p>
  </xsl:template>
  
  <xsl:template match="Mandatory[not(@Feedback) or @Feedback != 'none']" mode="pre">
    <xsl:param name="key"/>
    <xsl:attribute name="data-binding">mandatory</xsl:attribute>
    <xsl:attribute name="data-variable">_undef</xsl:attribute>
    <xsl:attribute name="data-validation">off</xsl:attribute>
    <xsl:attribute name="data-mandatory-invalid-class">af-mandatory</xsl:attribute>
    <xsl:attribute name="data-mandatory-type">
      <xsl:choose>
        <xsl:when test="//Form/Plugins/Input[contains(@Keys, $key)]">input</xsl:when>
        <xsl:when test="//Form/Plugins/Text[contains(@Keys, $key) or (@Prefix and starts-with($key, @Prefix))]">p</xsl:when>
        <xsl:when test="//Form/Plugins/MultiText[contains(@Keys, $key) or (@Prefix and starts-with($key, @Prefix))]">textarea</xsl:when>
        <xsl:otherwise>ul</xsl:otherwise> <!-- assuming dynamically generated item lists/radio buttons (ie select2/choice2) -->
      </xsl:choose>
    </xsl:attribute>
  </xsl:template>

  <!-- assumes 'off' to turn off red borders feedback -->
  <xsl:template match="Mandatory[@Feedback = 'none']" mode="pre"></xsl:template>

  <xsl:template match="@Message-loc">
    <xsl:attribute name="loc"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <xsl:template match="@Pattern">
    <xsl:attribute name="data-pattern"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>
  
  <xsl:template match="Condition">
    <xsl:attribute name="data-binding">switch</xsl:attribute>
    <xsl:attribute name="data-variable"><xsl:value-of select="@Variable"/></xsl:attribute>
    <xsl:apply-templates select="@DisableClass"/>
  </xsl:template>

  <xsl:template match="@DisableClass">
    <xsl:attribute name="data-disable-class"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>
  
  <xsl:template match="Ajax">
    <xsl:param name="key">key</xsl:param>
    <xsl:choose>
      <xsl:when test="$key = @Source">
        <xsl:copy-of select="@data-ajax-scope"/>
        <xsl:attribute name="data-binding">ajax</xsl:attribute>
        <xsl:attribute name="data-variable"><xsl:value-of select="@Source"/></xsl:attribute>
        <xsl:attribute name="data-ajax-url"><xsl:value-of select="@Service"/></xsl:attribute>
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="data-ajax-trigger"><xsl:value-of select="@Source"/></xsl:attribute>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="Binding">
    <xsl:attribute name="data-binding"><xsl:value-of select="@Name"/></xsl:attribute>
    <xsl:copy-of select="@*[starts-with(local-name(),'data-')]"/>
  </xsl:template>

  <!-- ************************* -->
  <!--         Plugins           -->
  <!-- ************************* -->
  
  <xsl:template name="Input">
    <xsl:param name="key"/>
    <xsl:param name="tag"/>
    <xsl:param name="span">span</xsl:param>
    <xsl:variable name="filter">
      <xsl:if test="@Filter"><xsl:value-of select="@Filter"/><xsl:text> </xsl:text></xsl:if>
      <xsl:text>optional</xsl:text>
      <xsl:if test="/Form/Bindings/Enforce/*[contains(@Keys, $key)] or /Form/Hints/Mandatory[not(@Feedback) or @Feedback != 'none'][contains(@Tags, $tag) or contains(@Keys, $key)]"><xsl:text> </xsl:text>event</xsl:if>
    </xsl:variable>
    <xsl:variable name="klass">
      <xsl:if test="@Class"><xsl:text> </xsl:text><xsl:value-of select="@Class"/></xsl:if>
    </xsl:variable>
    <xsl:variable name="required">
      <xsl:if test="//Form/Bindings/Require[contains(@Keys, $key)]">;required=true</xsl:if>
    </xsl:variable>
    <xsl:variable name="type">
      <xsl:if test="@Type">type=<xsl:value-of select="@Type"/>;</xsl:if>
    </xsl:variable>
    <xsl:variable name="media">
      <xsl:if test="@Media">;constant_media=<xsl:value-of select="@Media"/></xsl:if>
    </xsl:variable>
    <xsl:variable name="xvalue">
      <xsl:if test="@Tag">;xvalue=<xsl:value-of select="@Tag"/></xsl:if>
    </xsl:variable>
    <xsl:variable name="uppercase">
      <xsl:if test="@Filter[. = 'list']">;list_uppercase=true</xsl:if>
    </xsl:variable>
    <xt:use label="{//Field[@Key = $key]/@Tag}" param="{$type}filter={$filter};class={$span} a-control{$klass}{$required}{$media}{$xvalue}{$uppercase}" types="input"/>
  </xsl:template>

  <!--  FIXME: event filter iff there is an associated binding -->
  <xsl:template match="Input">
    <xsl:param name="key"/>
    <xsl:call-template name="Input">
      <xsl:with-param name="key"><xsl:value-of select="$key"/></xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <!-- @fill + div.absolute is a trick to set the input element to fill its parent's container space using CSS rules -->
  <xsl:template match="Input[@Append]">
    <xsl:param name="key"/>
    <xsl:copy-of select="//Field[@Key = $key]/@Tag"/>
    <xsl:attribute name="signature">append</xsl:attribute>
    <div class="input-append fill">
      <div class="absolute">
        <xsl:call-template name="Input">
          <xsl:with-param name="key"><xsl:value-of select="$key"/></xsl:with-param>
          <xsl:with-param name="span">fill</xsl:with-param>
        </xsl:call-template>
      </div>
      <span class="add-on fill"><xsl:value-of select="@Append"/></span>
    </div>
  </xsl:template>

  <!-- Replaces parent's class attribute (FIXME: check if every XSLT implementation allows that !) -->
  <xsl:template match="RichText" mode="pre">
    <xsl:attribute name="class">control-group <xsl:value-of select="@Menu"/></xsl:attribute>
  </xsl:template>

  <!-- FIXME: limitation - non sharable Keys  -->
  <xsl:template match="RichText">
    <xsl:param name="key"></xsl:param>
    <xsl:attribute name="signature">richtext</xsl:attribute>
    <div class="span a-control af-html-edit">
      <xt:repeat minOccurs="0" maxOccurs="*" label="{//Field[@Key = $key]/@Tag}">
        <xt:use types="t_{@Menu}_row"/>
      </xt:repeat>
    </div>
  </xsl:template>

  <!-- FIXME: limitation - non sharable Keys -->
  <xsl:template match="Text">
    <xsl:param name="key"></xsl:param>
    <xsl:param name="tag"></xsl:param>
    <xsl:variable name="required">
      <xsl:if test="//Form/Bindings/Require[contains(@Keys, $key)]">;required=true</xsl:if>
    </xsl:variable>
    <xsl:variable name="event">
      <xsl:if test="//Form/Hints/Mandatory[contains(@Tags, $tag)]"> event</xsl:if>
    </xsl:variable>
    <xt:use types="text" label="{//Field[@Key = $key]/@Tag}" handle="p" param="type=textarea;placeholder=empty;shape=parent;class=sg-textarea span a-control;filter=optional{$event}{$required}"/>
  </xsl:template>

  <xsl:template match="MultiText">
    <xsl:param name="key"/>
    <xsl:param name="tag"/>
    <xsl:attribute name="signature">multitext</xsl:attribute>
    <xsl:variable name="filter">
      <xsl:if test="@Filter"><xsl:value-of select="@Filter"/><xsl:text> </xsl:text></xsl:if>
      <xsl:text>optional</xsl:text>
      <xsl:if test="/Form/Bindings/Enforce/*[contains(@Keys, $key)] or /Form/Hints/Mandatory[not(@Feedback) or @Feedback != 'none'][contains(@Tags, $tag) or contains(@Keys, $key)]"><xsl:text> </xsl:text>event</xsl:if>
    </xsl:variable>
    <xsl:variable name="required">
      <xsl:if test="//Form/Bindings/Require[contains(@Keys, $key)]">;required=true</xsl:if>
    </xsl:variable>
    <xsl:variable name="mode">
      <xsl:choose>
        <xsl:when test="@Mode"><xsl:value-of select="@Mode"/></xsl:when>
        <xsl:otherwise>normal</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="event">
      <xsl:if test="//Form/Hints/Mandatory[contains(@Tags, $tag)]"> event</xsl:if>
    </xsl:variable>
    <xt:use types="input" label="{//Field[@Key = $key]/@Tag}" param="type=textarea;multilines={$mode};class=sg-multitext span a-control;filter={$filter}{$required}"/>
  </xsl:template>
  
  <!-- Warning: do not make confusion with <Constant> field (w/o label) -->
  <!-- FIXME: support @id directly on xt:use in AXEL ?  -->
  <xsl:template match="Constant">
    <xsl:param name="key"></xsl:param>
    <xsl:variable name="id"><xsl:if test="//Field[@Key = $key]/@Id">;id=<xsl:value-of select="//Field[@Key = $key]/@Id"/></xsl:if></xsl:variable>
    <xsl:variable name="media"><xsl:if test="./@Media">;constant_media=<xsl:value-of select="@Media"/></xsl:if></xsl:variable>
    <xt:use types="constant" label="{//Field[@Key = $key]/@Tag}" param="class=uneditable-input span a-control{$media}{$id};{@Param}"/>
  </xsl:template>
  
  <!-- FIXME: no need to wrapped inside a site:field since no need for filtering ? -->
  <xsl:template match="Constant[@Append]">
    <xsl:param name="key"></xsl:param>
    <xsl:variable name="id"><xsl:if test="//Field[@Key = $key]/@Id">;id=<xsl:value-of select="//Field[@Key = $key]/@Id"/></xsl:if></xsl:variable>
    <xsl:variable name="xtraklass">
      <xsl:if test="@Class"><xsl:text> </xsl:text><xsl:value-of select="@Class"/></xsl:if>
    </xsl:variable>
    <div class="input-append fill">
      <xt:use types="constant" label="{//Field[@Key = $key]/@Tag}" param="class=uneditable-input fill a-control{$xtraklass}{$id};{@Param}"/>
      <span class="add-on fill"><xsl:value-of select="@Append"/></span>
    </div>
  </xsl:template>

  <!--  'html' plugin to render multilines text with blender   -->
  <xsl:template match="Constant[@Media = 'html']">
    <xsl:param name="key"></xsl:param>
    <xt:use types="html" label="{//Field[@Key = $key]/@Tag}" param="class=span a-control"/>
  </xsl:template>

  <!-- FIXME: to localize Calendar component would require to generate Date field in form.xql to inject language (?) -->
  <xsl:template match="Date">
    <xsl:param name="key"></xsl:param>
    <xt:use label="{//Field[@Key = $key]/@Tag}" param="filter=optional;type=date;date_region=en;date_format=ISO_8601;class=date;class=span a-control" types="input"></xt:use>
  </xsl:template>
  
  <xsl:template match="Plain[@Type = 'constant']">
    <xsl:param name="key"></xsl:param>
    <xsl:attribute name="signature">plain</xsl:attribute>
    <xsl:attribute name="class">sg-plain</xsl:attribute>
    <xt:use types="constant" label="{//Field[@Key = $key]/@Tag}"/>
  </xsl:template>

  <xsl:template match="Plain[@Type = 'text']">
    <xsl:param name="key"></xsl:param>
    <xsl:attribute name="signature">plain</xsl:attribute>
    <xsl:attribute name="class">sg-plain</xsl:attribute>
    <xt:use types="text" label="{//Field[@Key = $key]/@Tag}" handle="p" param="filter=event;type=textarea;shape=parent-30px;placeholder=clear;class=sg-plain"><xsl:value-of select="."/></xt:use>
  </xsl:template>

  <xsl:template match="Plain[@Type = 'number']">
    <xsl:param name="key"></xsl:param>
    <xsl:attribute name="signature">plain</xsl:attribute>
    <xt:use types="input" label="{//Field[@Key = $key]/@Tag}" param="filter=event;type=text;class=sg-plain sg-number"></xt:use>
  </xsl:template>

  <!-- <xsl:template match="Plain[@Constant = 'yes']">
    <xsl:param name="key"></xsl:param>
    <xsl:param name="pos">y</xsl:param>
    <xt:use types="constant" label="{//Field[count(preceding::Field[string(@Key) = $key]) = $pos]/@Tag}"><xsl:value-of select="$pos"/>:<xsl:value-of select="$key"/></xt:use>
    </xsl:template> -->

  <!-- ************************* -->
  <!--         Commands          -->
  <!-- ************************* -->

  <xsl:template match="Augment">
    <xsl:param name="key"></xsl:param>
    <xsl:attribute name="data-command">augment</xsl:attribute>
    <xsl:attribute name="data-target"><xsl:value-of select="@TargetEditor"/></xsl:attribute>
    <xsl:attribute name="data-augment-field"><xsl:value-of select="@TargetField"/></xsl:attribute>
    <xsl:if test="@TargetRoot">
      <xsl:attribute name="data-augment-root"><xsl:value-of select="@TargetRoot"/></xsl:attribute>
    </xsl:if>
    <xsl:attribute name="data-{@Mode}-src"><xsl:value-of select="concat($xslt.base-url, @Controller)"/></xsl:attribute>
    <xsl:attribute name="data-augment-mode"><xsl:value-of select="@Mode"/></xsl:attribute>
    <xsl:apply-templates select="@loc" mode="augment"/>
  </xsl:template>

  <xsl:template match="@loc" mode="augment">
    <xsl:attribute name="data-augment-noref-loc"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <xsl:template match="Add">
    <xsl:param name="key"></xsl:param>
    <xsl:apply-templates select="@Id"/>
    <xsl:attribute name="data-command">add</xsl:attribute>
    <xsl:attribute name="data-target"><xsl:value-of select="@TargetEditor"/></xsl:attribute>
    <xsl:attribute name="data-target-modal"><xsl:value-of select="@TargetEditor"/>-modal</xsl:attribute>
    <xsl:apply-templates select="@Resource | @Controller | @Template | @TitleKey | @TargetTitle" mode="add"/>
  </xsl:template>

  <xsl:template match="Show">
    <xsl:param name="key"></xsl:param>
    <xsl:apply-templates select="@Id"/>
    <xsl:attribute name="data-command">show</xsl:attribute>
    <xsl:attribute name="data-target-modal"><xsl:value-of select="@TargetModal"/>-modal</xsl:attribute>
    <xsl:apply-templates select="@Controller | @TitleKey | @TargetTitle" mode="add"/>
    <xsl:attribute name="data-value-source"><xsl:value-of select="@DataSource"/></xsl:attribute>
  </xsl:template>

  <xsl:template match="@Resource" mode="add">
    <xsl:attribute name="data-edit-action">update</xsl:attribute>
    <xsl:attribute name="data-src"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <!-- FIXME: check url does not start with tilde -->
  <xsl:template match="@Controller" mode="add">
    <xsl:attribute name="data-edit-action">create</xsl:attribute>
    <xsl:attribute name="data-src"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>
  
  <xsl:template match="@Template" mode="add">
    <xsl:attribute name="data-with-template"><xsl:value-of select="concat($xslt.base-url, .)"/></xsl:attribute>
  </xsl:template>
  
  <!-- FIXME: check url start with tilde -->
  <!-- FIXME: relative URL to localize template ? -->
  <xsl:template match="@Template[starts-with(.,'^')]" mode="add">
    <xsl:attribute name="data-with-template"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <xsl:template match="@TitleKey" mode="add">
    <xsl:attribute name="data-add-key"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <xsl:template match="@TargetTitle" mode="add">
    <xsl:attribute name="data-title-scope"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <xsl:template match="Open" mode="install">
    <form id="{@Form}" method="get" target="_blank" style="display:none"/>    
  </xsl:template>

  <xsl:template match="Open">
    <xsl:apply-templates select="@Id"/>
    <xsl:attribute name="data-command">open</xsl:attribute>
    <xsl:attribute name="data-src"><xsl:value-of select="@Resource"/></xsl:attribute>
    <xsl:attribute name="data-form"><xsl:value-of select="@Form"/></xsl:attribute>
  </xsl:template>

  <!-- ************************* -->
  <!--         Modals            -->
  <!-- ************************* -->

  <!-- Calculer margin-left ! -->
  <xsl:template match="Modal" mode="component">
    <xsl:variable name="label4save">
      <xsl:choose>
        <xsl:when test="@SaveLabel"><xsl:value-of select="@SaveLabel"/></xsl:when>
        <xsl:otherwise>action.save</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="margin"><xsl:value-of select="number(substring-before(@Width,'px')) div 2"/></xsl:variable>
    <xsl:comment>Modal dialog window</xsl:comment>
    <xt:component name="t_{@Id}">
      <div id="{@Id}-modal" aria-hidden="true" role="dialog" tabindex="-1" class="modal hide fade" style="width:{@Width};margin-left:-{$margin}px"
        data-backdrop="static" data-keyboard="false">
        <div class="modal-header">
            <button aria-hidden="true" data-dismiss="modal" class="close" type="button">×</button>
            <h3><xsl:apply-templates select="Title" mode="modal"/></h3>
        </div>
        <div class="modal-body">
          <div id="{@Id}" data-command="transform">
            <xsl:apply-templates select="@Template" mode="modal"/>
            <xsl:apply-templates select="@Gap" mode="modal"/>
          </div>
        </div>
        <div class="modal-footer c-menu-scope">
          <div id="{@Id}-errors" class="alert alert-error af-validation">
            <button type="button" class="close" data-dismiss="alert">x</button>
          </div>
          <button class="btn btn-primary" data-command="save c-inhibit" data-target="{@Id}"
            data-validation-output="{@Id}-errors" data-validation-label="label" loc="{$label4save}">
            <xsl:apply-templates select="@EventTarget"/>
            <xsl:choose>
              <xsl:when test="@AppenderId">
                <xsl:attribute name="data-replace-type">event append</xsl:attribute>
                <xsl:attribute name="data-replace-target"><xsl:value-of select="@AppenderId"/></xsl:attribute>
              </xsl:when>
              <xsl:when test="@PrependerId">
                <xsl:attribute name="data-replace-type">event prepend</xsl:attribute>
                <xsl:attribute name="data-replace-target"><xsl:value-of select="@PrependerId"/></xsl:attribute>
              </xsl:when>
              <xsl:otherwise>
                <xsl:attribute name="data-replace-type">event</xsl:attribute>
              </xsl:otherwise>
            </xsl:choose>
            Enregistrer</button>
          <button class="btn" data-command="trigger" data-target="{@Id}" data-trigger-event="axel-cancel-edit" loc="action.cancel">Annuler</button>
        </div>
      </div>
    </xt:component>
  </xsl:template>

  <!-- Calculer margin-left ! -->
  <xsl:template match="Modal[@Appearance = 'plain']" mode="component">
    <xsl:variable name="margin"><xsl:value-of select="number(substring-before(@Width,'px')) div 2"/></xsl:variable>
    <xsl:comment>Modal dialog window</xsl:comment>
    <xt:component name="t_{@Id}">
      <div id="{@Id}-modal" aria-hidden="true" role="dialog" tabindex="-1" class="modal hide fade" style="width:{@Width};margin-left:-{$margin}px"
        data-backdrop="static" data-keyboard="false">
        <div class="modal-header">
            <button aria-hidden="true" data-dismiss="modal" class="close" type="button">×</button>
            <h3><xsl:apply-templates select="Title" mode="modal"/></h3>
        </div>
        <div class="modal-body">
        </div>
      </div>
    </xt:component>
  </xsl:template>

  <xsl:template match="@Template" mode="modal">
    <xsl:attribute name="data-template"><xsl:value-of select="$xslt.base-url"/><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <xsl:template match="@Template[starts-with(.,'^')]" mode="modal">
    <xsl:attribute name="data-template"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <xsl:template match="@EventTarget">
    <xsl:attribute name="data-event-target"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <!-- Adds a left margin to the modal body, this has been added for instance to leave space 
       for hierarchical drop down lists opening left side (i.e. choice2_position="left") -->
  <xsl:template match="@Gap" mode="modal">
    <xsl:attribute name="style">margin-left:<xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <xsl:template match="Title" mode="modal">
    <xsl:copy-of select="@loc"/><xsl:value-of select="."/>
  </xsl:template>

  <xsl:template match="Title[@Key]" mode="modal">
    <xsl:attribute name="data-when-{@Key}"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <!-- localized @Mode -->
  <xsl:template match="Title[@Mode]" mode="modal">
    <xsl:attribute name="data-when-{@Mode}-loc"><xsl:value-of select="@loc"/></xsl:attribute>
  </xsl:template>

  <xsl:template match="Modal">
      <xt:use types="t_{@Id}"/>
  </xsl:template>

  <!-- ************************* -->
  <!--         Shared            -->
  <!-- ************************* -->

  <xsl:template match="@Id">
    <xsl:attribute name="id"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <xsl:template match="Service-EndPoint">
    <xsl:variable name="target"><xsl:value-of select="@TargetId"/></xsl:variable>
    <xsl:variable name="element"><xsl:value-of select="@TargetElement"/></xsl:variable>
    <xsl:attribute name="{@Name}"><xsl:value-of select="document(@Source)//EndPoint[Id = 'ccmatch.suggest']/*[local-name(.) = $element]"/></xsl:attribute>
  </xsl:template>

  <!-- ************************* -->
  <!--         Include           -->
  <!-- ************************* -->

  <xsl:template match="Include" mode="component">
    <xsl:variable name="label">
      <xsl:value-of select="document(concat($xslt.base-root, concat($xslt.base-formulars, @src)))/*/@Tag"/>
    </xsl:variable>
    <xsl:apply-templates select="document(concat($xslt.base-root, concat($xslt.base-formulars, @src)))//Verbatim/*"/>
    <xsl:apply-templates select="document(concat($xslt.base-root, concat($xslt.base-formulars, @src)))//Cell[@Tag]|document(concat($xslt.base-root, concat($xslt.base-formulars, @src)))//Cell[not(@Tag) and @TypeName]|document(concat($xslt.base-root, concat($xslt.base-formulars, @src)))//Box|document(concat($xslt.base-root, concat($xslt.base-formulars, @src)))//Plugins/Component/*" mode="component"/>
    <xsl:apply-templates select="document(concat($xslt.base-root, concat($xslt.base-formulars, @src)))/Poll" mode="head"/>
    <xt:component name="t_{$label}_include">
      <xsl:apply-templates select="document(concat($xslt.base-root, concat($xslt.base-formulars, @src)))/Form/Row[not(@Include) = 'false']"/>
      <xsl:apply-templates select="document(concat($xslt.base-root, concat($xslt.base-formulars, @src)))/Poll" mode="body"/>
    </xt:component>
  </xsl:template>

  <xsl:template match="Include">
    <xsl:variable name="label">
      <xsl:value-of select="document(concat($xslt.base-root, concat($xslt.base-formulars, @src)))/*/@Tag"/>
    </xsl:variable>
    <xt:use types="t_{$label }_include" label="{ $label }"/>
  </xsl:template>

  <!-- ************************* -->
  <!--         Copy              -->
  <!-- ************************* -->
  
  <!-- trick to avoid namespace prefix destruction  -->
  <xsl:template match="xt:use">
    <xt:use>
      <xsl:copy-of select="@*|text()"/>
    </xt:use>
  </xsl:template>

  <!-- trick to avoid namespace prefix destruction  -->
  <xsl:template match="xt:repeat">
    <xt:repeat>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="*"/>
    </xt:repeat>
  </xsl:template>
  
  <!-- trick to avoid namespace prefix destruction  -->
  <xsl:template match="xt:menu-marker">
    <xt:menu-marker/>
  </xsl:template>
  
  <!-- trick to avoid namespace prefix destruction  -->
  <xsl:template match="xt:component">
    <xt:component>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="*"/>
    </xt:component>
  </xsl:template>
  
  <!-- trick to avoid namespace prefix destruction  -->
  <xsl:template match="site:conditional">
    <site:conditional>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="*"/>
    </site:conditional>
  </xsl:template>
  
  <!-- copy native site:field declarations as is (otherwise catch all rule below changes site prefix to sit w/o e) -->
  <xsl:template match="site:field">
    <site:field>
      <xsl:copy-of select="@*|*|text()"/>
    </site:field>
  </xsl:template>

  <xsl:template match="*|@*|text()">
    <xsl:copy>
      <xsl:apply-templates select="*|@*|text()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
