@EndUserText.label: 'Security access critical authorization'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_CRIT_AUTH_QUERY'
define custom entity ZC_SEC_CRIT_AUTH
{
  key AuthorizationId : abap.char(20);
  key CriticalGroup   : abap.char(4);
  key Object          : abap.char(10);
  key Field           : abap.char(10);
  key Low             : abap.char(40);
  key High            : abap.char(40);
      Client          : abap.char(3);
      SearchType      : abap.char(3);
      Color           : abap.char(1);
      TransactionCode : abap.char(20);
      Description     : abap.char(60);
}
