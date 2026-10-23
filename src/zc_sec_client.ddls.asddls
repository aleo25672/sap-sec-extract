@EndUserText.label: 'Client settings'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_CLIENT_QUERY'
define custom entity ZC_SEC_CLIENT
{
  key Client                    : abap.clnt;
      ClientName                : abap.char(25);
      ClientRole                : abap.char(1);
      ClientRoleText            : abap.char(60);
      ClientSpecificChanges     : abap.char(1);
      ClientSpecificChangesText : abap.char(80);
      CrossClientChanges        : abap.char(1);
      CrossClientChangesText    : abap.char(80);
      ClientCopyProtection      : abap.char(1);
      ClientCopyProtectionText  : abap.char(80);
      CattAllowed               : abap.char(1);
      CattAllowedText           : abap.char(80);
      UpgradeCascadeLocked      : abap.char(1);
      TemporarilyLocked         : abap.char(1);
      LogicalSystem             : abap.char(10);
      LastChangedBy             : abap.char(12);
      LastChangedOn             : abap.dats;
      TableChangeLogging        : abap.char(1);
}
