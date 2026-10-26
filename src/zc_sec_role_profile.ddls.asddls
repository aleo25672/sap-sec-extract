@EndUserText.label: 'Security access role profile'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_ROLE_PROFILE_QUERY'
define custom entity ZC_SEC_ROLE_PROFILE
{
  key RoleName    : abap.char(30);
  key Counter     : abap.numc(6);
      Client      : abap.char(3);
      ProfileName : abap.char(12);
      Variant     : abap.char(4);
      Generated   : abap.char(1);
      Version     : abap.char(1);
}
