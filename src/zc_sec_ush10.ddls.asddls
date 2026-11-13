@EndUserText.label: 'Profile change document'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_USH10_QUERY'
define custom entity ZC_SEC_USH10
{
  key ProfileName : abap.char(12);
  key Version     : abap.char(1);
  key ChangedOn   : abap.dats;
  key ChangedAt   : abap.tims;
      ChangedBy   : abap.char(12);
      Client      : abap.char(3);
}
