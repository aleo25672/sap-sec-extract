@AbapCatalog.sqlViewName: 'ZISEC_ROLE_ASGN'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Security access role assignment'
define view ZI_SEC_ROLE_ASSIGN
  as select from agr_users
{
  key agr_users.uname      as UserId,
  key agr_users.agr_name   as RoleName,
      agr_users.from_dat   as ValidFrom,
      agr_users.to_dat     as ValidTo,
      agr_users.exclude    as Excluded,
      agr_users.change_dat as ChangedOn,
      agr_users.col_flag   as FromCompositeRole,
      agr_users.org_flag   as FromOrgManagement
}
