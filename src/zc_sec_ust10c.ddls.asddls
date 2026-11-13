@EndUserText.label: 'Composite profile'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_UST10C_QUERY'
define custom entity ZC_SEC_UST10C
{
  key ProfileName : abap.char(12);
  key Version     : abap.char(1);
  key SubProfile  : abap.char(12);
      Client      : abap.char(3);
}
