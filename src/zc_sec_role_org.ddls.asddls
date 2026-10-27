@EndUserText.label: 'Security access role org level'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_ROLE_ORG_QUERY'
define custom entity ZC_SEC_ROLE_ORG
{
  key RoleName : abap.char(30);
  key Counter  : abap.numc(6);
      Client   : abap.char(3);
      Variable : abap.char(40);
      Low      : abap.char(40);
      High     : abap.char(40);
}
