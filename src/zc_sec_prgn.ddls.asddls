@EndUserText.label: 'Role customizing'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_PRGN_QUERY'
define custom entity ZC_SEC_PRGN
{
  key CustomizingId     : abap.char(20);
      CustomizingValue  : abap.char(10);
}
