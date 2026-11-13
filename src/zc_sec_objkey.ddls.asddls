@EndUserText.label: 'Object access registration'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_OBJKEY_QUERY'
define custom entity ZC_SEC_OBJKEY
{
  key ProgramId  : abap.char(4);
  key ObjectType : abap.char(4);
  key ObjectName : abap.char(120);
}
