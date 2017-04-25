xquery version "1.0";
(: --------------------------------------
   Case tracker pilote

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Generates user interface for several management functions

   May 2013 - (c) Copyright 2013 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

(: Deprecated legacy

<Tab Id="thesaurus">
  <Controller>management/thesaurus</Controller>
  <Name>Thesaurus</Name>
</Tab>

<Edit Id="c-thesaurus-editor" Width="800">
  <Name>Thesaurus</Name>
  <Template>management/thesaurus?template=1</Template>
</Edit>
:)

let $user := oppidum:get-current-user()
return
  <Page skin="management">
    <Window>Case Tracker Administration</Window>
    <Content>
      <Tabs>
        <Tab Id="users" class="active">
          <Controller>management/users</Controller>
          <Name>Users</Name>
          <h2>Instructions to administrators</h2>
          <p>Start by clicking on a tab on the left to do something...</p>
          <p>If while interacting with this page you open other windows to update companies and/or persons, do not forget to click again on the tab to reload the changes !</p>
        </Tab>
        {
        if ($user = 'admin') then (
          <Tab Id="groups">
            <Controller>management/groups</Controller>
            <Name>Groups</Name>
          </Tab>
          )
        else
          ()
        }
        <Tab Id="roles">
          <Controller>management/roles</Controller>
          <Name>Roles</Name>
        </Tab>
        <Tab Id="login">
          <Controller>management/login</Controller>
          <Name>Login</Name>
        </Tab>
        <Tab Id="access">
          <Controller>management/access</Controller>
          <Name>Access</Name>
        </Tab>
      </Tabs>
      <Modals>
        <Modal Id="c-person-editor" data-backdrop="static" data-keyboard="false">
          <Name>Person</Name>
          <Template>templates/person?goal=update</Template>
          <Commands>
            <Delete/>
            <Save data-replace-type="event"/>
            <Cancel/>
          </Commands>
        </Modal>
        <Modal Id="c-remote-editor" Width="700" data-backdrop="static" data-keyboard="false">
          <Name>Remote Profile</Name>
          <Template>templates/remote?goal=update</Template>
          <Commands>
            <Save data-replace-type="event"/>
            <Cancel/>
          </Commands>
        </Modal>
        <Modal Id="c-noremote-editor" Width="700" data-backdrop="static" data-keyboard="false">
          <Name>Remote Profile</Name>
          <Template>templates/remote?goal=create</Template>
          <Commands>
            <Save data-replace-type="event"/>
            <Cancel/>
          </Commands>
        </Modal>
        <Modal Id="c-profile-editor" Width="700" data-backdrop="static" data-keyboard="false">
          <Name>Profile</Name>
          <Template>templates/profile?goal=update</Template>
          <Commands>
            <Save data-replace-type="event"/>
            <Cancel/>
          </Commands>
        </Modal>
        <Modal Id="c-nologin-editor" data-backdrop="static" data-keyboard="false">
          <Name>Creation of a user account</Name>
          <Template>templates/account?goal=create</Template>
          <Commands>
            <Save>
              <Label>Create</Label>
            </Save>
            <Cancel/>
          </Commands>
        </Modal>
        <Modal Id="c-login-editor" data-backdrop="static" data-keyboard="false">
          <Name>Modification to a user account</Name>
          <Template>templates/account?goal=update</Template>
          <Commands>
            <LeftSide>
              <Password>New password</Password>
            </LeftSide>
            <Delete>
              <Confirm>Are you sure you want to withdraw access to the application to that user ? If you want to reestablish it later you will have to create a new login.</Confirm>
            </Delete>
            <Save>
              <Label>Change</Label>
            </Save>
            <Cancel/>
          </Commands>
        </Modal>
        {
        if ($user = 'admin') then
          <Modal Id="c-params-editor" Width="800" data-backdrop="static" data-keyboard="false">
            <Name>Application parameters</Name>
            <Template>management/params?goal=update</Template>
            <Commands>
              <Save/>
              <Cancel/>
            </Commands>
          </Modal>
        else
          ()
        }
      </Modals>
    </Content>
  </Page>
