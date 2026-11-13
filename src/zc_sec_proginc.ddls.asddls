@EndUserText.label: 'Program include'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_PROGINC_QUERY'
define custom entity ZC_SEC_PROGINC
{
  key ProgramName   : abap.char(40);
  key IncludeName   : abap.char(40);
}
