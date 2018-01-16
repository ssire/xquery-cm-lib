<?xml version="1.0" encoding="UTF-8"?>
<!--
     Case tracker pilote

     Creator: Stéphane Sire <s.sire@opppidoc.fr>

     FIXME: hard coded /db/sites/ctracker database path

     November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
  -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:site="http://oppidoc.com/oppidum/site" xmlns="http://www.w3.org/1999/xhtml">

  <xsl:output method="xml" media-type="text/html" omit-xml-declaration="yes" indent="yes"/>

  <xsl:param name="xslt.base-url">/</xsl:param>

  <xsl:template match="/Persons[not(Person)]">
    <div id="results">
      <p>Nobody</p>
    </div>
  </xsl:template>

  <xsl:template name="roles-legend">
    <xsl:variable name="gi">
      <xsl:value-of select="concat('xmldb:exist:///db/sites/ctracker/global-information/global-information-en.xml', '')"/>
    </xsl:variable>
    <div style="display: -webkit-flex; display: flex; flex-direction:row; -webkit-flex-direction:row; padding: 5px">
      <xsl:for-each select="document($gi)//Function">
        <xsl:if test="Brief != Name">
          <xsl:variable name="flex">flex:<xsl:value-of select="string-length(Name/text())"/> 0 0</xsl:variable>
          <div style="display: -webkit-flex; display: flex; flex-direction:column; -webkit-flex-direction:row; 
            -webkit-justify-content: flex-start; justify-content: flex-start;
            -webkit-align-self: flex-start; align-self: flex-start; padding : 0px 5px; {$flex}">
            <div style="margin:auto; padding-bottom: 5px; font-weight:bold; color: #004563;"><xsl:value-of select="Brief"/></div><div style="margin:auto; padding-bottom: 5px;"><xsl:value-of select="Name"/></div>
          </div>
        </xsl:if>
      </xsl:for-each>
    </div>
  </xsl:template>
  
  <xsl:template match="/Persons">
    <div id="results">
      <h1>Users management</h1>
      <p>The database references <b><xsl:value-of select="count(Person)"/></b> community member(s).</p>
      <p> Use the <i>Access</i> column to create a user login for the first time to grant access to the application to a member. Use the <i>Login</i> column to change or to revoke a user login, or to generate a new password for a user. Use the <i>roles</i> links to edit a user's Roles. Click on a user name to see and update his/her personal data. </p>
      <fieldgroup class="noprint" styme="clear:both">
        <!--<legend>Legend for shortened role name</legend>
        <xsl:call-template name="roles-legend"/>-->
        <p>Click on a column header to sort the table</p>
      </fieldgroup>
      <div id="results-export">
        <a download="results.xls" href="#" class="btn btn-primary export">Generate Excel</a>
        <a download="results.csv" href="#" class="btn btn-primary export">Generate CSV</a>
        <a download="results.xls" href="#" class="btn export">Reset filters</a>
      </div>
      <br/>
      <table name="users" class="table table-bordered todo" style="font-size:8pt">
        <thead>
          <tr>
            <th style="min-width:180px">Name <span style="font-weight:normal;display:block"><input style="width:170px" id="user-filter"/></span></th>
            <th>Email</th>
            <th>Country<span style="font-weight:normal;display:block"><input style="width:50px" id="country-filter"/></span></th>
            <th>Roles<span style="font-weight:normal;display:block"><input style="width:50px" id="role-filter"/></span></th>
            <th>Login</th>
            <th>Access</th>
          </tr>
        </thead>
        <tbody>
          <xsl:apply-templates select="Person"/>
        </tbody>
      </table>
    </div>
  </xsl:template>

  <xsl:template match="Person">
    <tr class="unstyled">
      <td>
        <xsl:apply-templates select="Name"/>
      </td>
      <td>
        <xsl:apply-templates select="Email"/>
      </td>
      <td>
        <xsl:apply-templates select="Country"/>
      </td>
      <td>
        <xsl:apply-templates select="Roles"/>
      </td>
      <td>
        <xsl:choose>
          <xsl:when test="@Login">
            <a data-login="accounts/{Id}">
              <xsl:value-of select="Username"/>
            </a>
          </xsl:when>
          <xsl:when test="Username">
            <a data-login="accounts/{Id}">
              <xsl:value-of select="Username"/>
            </a>
          </xsl:when>
          <xsl:otherwise> --- </xsl:otherwise>
        </xsl:choose>
      </td>
      <td>
        <xsl:choose>
          <xsl:when test="@Login"> yes </xsl:when>
          <xsl:when test="Username"> no </xsl:when>
          <xsl:otherwise>
            <a data-nologin="accounts/{Id}">create</a>
          </xsl:otherwise>
        </xsl:choose>
      </td>
    </tr>
  </xsl:template>

  <!-- FIXME: afficher fenêtre modale idem annuaire en mode édition -->
  <xsl:template match="Name">
    <a data-person="persons/{../Id}">
      <span class="fn"><xsl:value-of select="LastName/text()"/></span><xsl:text> </xsl:text><xsl:value-of select="FirstName/text()"/>
    </a>
  </xsl:template>

  <xsl:template match="Email">
    <xsl:value-of select="."/>
  </xsl:template>

  <xsl:template match="Country">
    <span class="cn">
      <xsl:variable name="gi">
        <xsl:value-of select="concat('xmldb:exist:///db/sites/ctracker/global-information/countries-en.xml', '')"/>
      </xsl:variable>
      <xsl:variable name="cref">
        <xsl:value-of select="."/>
      </xsl:variable>
      <xsl:value-of select="string(document($gi)//CountryName[../CountryCode = $cref])"/>
    </span>
  </xsl:template>

  <xsl:template match="Roles">
    <a><span class="rn" data-profile="profiles/{../Id}"><xsl:value-of select="."/></span></a>
  </xsl:template>

</xsl:stylesheet>
