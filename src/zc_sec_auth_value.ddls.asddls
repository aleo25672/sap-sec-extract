@EndUserText.label: 'Security access authorization value'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_AUTH_VALUE_QUERY'
define custom entity ZC_SEC_AUTH_VALUE
{
  key Object        : abap.char(10);
  key AuthName      : abap.char(12);
  key Version       : abap.char(1);
  key Field         : abap.char(10);
  key Low           : abap.char(40);
  key High          : abap.char(40);
      Client        : abap.char(3);
}
