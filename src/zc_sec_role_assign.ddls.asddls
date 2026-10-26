@EndUserText.label: 'Security access role assignment'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_ROLE_ASSIGN_QUERY'
define custom entity ZC_SEC_ROLE_ASSIGN
{
  key UserId              : abap.char(12);
  key RoleName            : abap.char(30);
      Client              : abap.clnt;
      ValidFrom           : abap.dats;
      ValidTo             : abap.dats;
      Exclusive           : abap.char(1);
      ChangedOn           : abap.dats;
      FromCompositeRole   : abap.char(1);
      FromOrgManagement   : abap.char(1);
}
