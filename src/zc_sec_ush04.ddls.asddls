@EndUserText.label: 'Profile assignment history'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_USH04_QUERY'
define custom entity ZC_SEC_USH04
{
  key UserName     : abap.char(12);
  key ChangedOn    : abap.dats;
  key ChangedAt    : abap.tims;
      ChangedBy    : abap.char(12);
      Client       : abap.char(3);
      ProfileCount : abap.int2;
      ProfileList  : abap.string(0);
}
