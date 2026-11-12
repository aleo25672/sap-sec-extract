@EndUserText.label: 'Security audit filter event'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_SALFLT_QUERY'
define custom entity ZC_SEC_SALFLT
{
  key Source      : abap.char(7);
  key HostName    : abap.char(32);
  key ProfileName : abap.char(8);
  key SlotNumber  : abap.numc(4);
  key LineKind    : abap.char(5);
  key LineValue   : abap.char(20);
      Client      : abap.char(3);
      UserName    : abap.char(12);
      SlotStatus  : abap.char(1);
}
