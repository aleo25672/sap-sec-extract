@EndUserText.label: 'Table change log'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_DBLOG_QUERY'
define custom entity ZC_SEC_DBLOG
{
  key LogDate          : abap.dats;
  key LogTime          : abap.tims;
  key LogId            : abap.char(18);
      TableName        : abap.char(30);
      RecordKey        : abap.char(250);
      HostName         : abap.char(20);
      UserName         : abap.char(12);
      TransactionCode  : abap.char(20);
      ProgramName      : abap.char(40);
      Operation        : abap.char(1);
      OperationText    : abap.char(10);
      VersionNumber    : abap.char(2);
      Language         : abap.char(1);
}
