@EndUserText.label: 'Security access profile authorization'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_PROF_AUTH_QUERY'
define custom entity ZC_SEC_PROF_AUTH
{
  key ProfileName   : abap.char(12);
  key Version       : abap.char(1);
  key Object        : abap.char(10);
  key AuthName      : abap.char(12);
      Client        : abap.char(3);
}
