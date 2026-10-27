@EndUserText.label: 'Security access profile'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_PROFILE_QUERY'
define custom entity ZC_SEC_PROFILE
{
  key ProfileName         : abap.char(12);
  key Version             : abap.char(1);
      Client              : abap.char(3);
      ProfileType         : abap.char(1);
      ChangedBy           : abap.char(12);
      ChangedOn           : abap.dats;
      ChangedAt           : abap.tims;
      Department          : abap.char(10);
      AuthorizationCount  : abap.int2;
      Description         : abap.char(60);
}
