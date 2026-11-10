@EndUserText.label: 'Import history'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_TPALOG_QUERY'
define custom entity ZC_SEC_TPALOG
{
  key ImportTimestamp : abap.numc(14);
  key Request         : abap.char(20);
  key TargetSystem    : abap.char(10);
  key SourceClient    : abap.char(3);
  key Step            : abap.char(1);
      ImportOn        : abap.dats;
      AllClients      : abap.char(1);
      Project         : abap.char(20);
      UserName        : abap.char(12);
      ReturnCode      : abap.char(4);
      ReturnCodeText  : abap.char(20);
      HostName        : abap.char(32);
      Administrator   : abap.char(12);
}
