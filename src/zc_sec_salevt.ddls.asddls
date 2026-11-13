@EndUserText.label: 'Security audit event'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_SALEVT_QUERY'
define custom entity ZC_SEC_SALEVT
{
  key MessageArea      : abap.char(2);
  key MessageSubid     : abap.char(1);
  key EventTimestamp   : abap.char(16);
  key ProcessId        : abap.char(12);
  key Client           : abap.char(3);
  key SystemId         : abap.char(8);
  key InstanceName     : abap.char(40);
  key Counter          : abap.int2;
      MessageId        : abap.char(3);
      EventOn          : abap.dats;
      Terminal         : abap.char(20);
      UserName         : abap.char(12);
      TransactionCode  : abap.char(20);
      ProgramName      : abap.char(40);
      TerminalAddress  : abap.char(45);
      EventData        : abap.string(0);
}
