@EndUserText.label: 'Developer key'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_DEVKEY_QUERY'
define custom entity ZC_SEC_DEVKEY
{
  key UserName : abap.char(12);
}
