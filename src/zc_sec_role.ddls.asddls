@EndUserText.label: 'Security access role'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_ROLE_QUERY'
define custom entity ZC_SEC_ROLE
{
  key RoleName     : abap.char(30);
      Client       : abap.char(3);
      ParentRole   : abap.char(30);
      Description  : abap.char(80);
      CreatedBy    : abap.char(12);
      CreatedOn    : abap.dats;
      ChangedBy    : abap.char(12);
      ChangedOn    : abap.dats;
}
