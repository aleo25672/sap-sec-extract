@EndUserText.label: 'Forbidden password'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_USR40_QUERY'
define custom entity ZC_SEC_USR40
{
  key PasswordPattern  : abap.char(40);
      CaseSensitive    : abap.char(1);
}
