@EndUserText.label: 'Transport request object'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_E071_QUERY'
define custom entity ZC_SEC_E071
{
  key Request       : abap.char(20);
  key ObjectPosition : abap.numc(6);
      ProgramId     : abap.char(4);
      ObjectType    : abap.char(4);
      ObjectName    : abap.char(120);
      ObjectFunction : abap.char(1);
      ObjectLanguage : abap.char(1);
      Owner         : abap.char(12);
      ChangedOn     : abap.dats;
      TargetSystem  : abap.char(10);
      RequestStatus : abap.char(1);
      Description   : abap.char(60);
}
