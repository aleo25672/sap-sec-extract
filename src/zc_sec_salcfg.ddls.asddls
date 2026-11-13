@EndUserText.label: 'Security audit configuration'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_SALCFG_QUERY'
define custom entity ZC_SEC_SALCFG
{
  key ProfileName    : abap.char(8);
  key SlotNumber     : abap.numc(4);
      ActiveProfile  : abap.char(8);
      AuditClasses   : abap.int4;
      AuditClassText : abap.char(120);
      Severity       : abap.int4;
      SeverityText   : abap.char(10);
      Client         : abap.char(3);
      UserName       : abap.char(12);
      SlotStatus     : abap.char(1);
      ChangedBy      : abap.char(12);
      ChangedOn      : abap.dats;
}
