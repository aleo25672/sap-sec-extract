@EndUserText.label: 'Security access role authorization'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_ROLE_AUTH_QUERY'
define custom entity ZC_SEC_ROLE_AUTH
{
  key RoleName      : abap.char(30);
  key Counter       : abap.numc(6);
      Client        : abap.char(3);
      Object        : abap.char(10);
      Authorization : abap.char(12);
      Variant       : abap.char(4);
      Field         : abap.char(10);
      Low           : abap.char(40);
      High          : abap.char(40);
      Modified      : abap.char(1);
      Deleted       : abap.char(1);
      Copied        : abap.char(1);
      NewEntry      : abap.char(1);
}
