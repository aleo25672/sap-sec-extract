@EndUserText.label: 'Security access critical variant'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_CRIT_VAR_QUERY'
define custom entity ZC_SEC_CRIT_VAR
{
  key VariantName     : abap.char(20);
  key AuthorizationId : abap.char(20);
      Client          : abap.char(3);
}
