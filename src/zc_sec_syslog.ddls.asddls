@EndUserText.label: 'System log'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_SYSLOG_QUERY'
define custom entity ZC_SEC_SYSLOG
{
  key InstanceName     : abap.char(20);
  key FileNumber       : abap.numc(6);
  key FilePosition     : abap.numc(10);
      EventOn          : abap.dats;
      EventAt          : abap.tims;
      MessageId        : abap.char(3);
      Client           : abap.char(3);
      UserName         : abap.char(12);
      TransactionCode  : abap.char(20);
      ProgramName      : abap.char(40);
      Terminal         : abap.char(8);
      MessageData      : abap.char(64);
}
