@EndUserText.label: 'System status'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_SYSTEM_QUERY'
define custom entity ZC_SEC_SYSTEM
{
  key SystemId            : abap.char(8);
  key ApplicationServer   : abap.char(32);
      DatabaseSystem      : abap.char(10);
      DatabaseHost        : abap.char(32);
      DatabaseRelease     : abap.string(0);
      OperatingSystem     : abap.char(10);
      MachineType         : abap.char(5);
      IpAddress           : abap.char(45);
      SapRelease          : abap.char(4);
      UnicodeSystem       : abap.char(1);
      InstallationNumber  : abap.char(10);
}
