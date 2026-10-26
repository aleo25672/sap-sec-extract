@AbapCatalog.sqlViewName: 'ZISEC_ROLE_PROF'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Security access role profile'
define view ZI_SEC_ROLE_PROFILE
  as select from agr_1016
{
  key agr_1016.agr_name  as RoleName,
  key agr_1016.counter   as Counter,
      agr_1016.profile   as ProfileName,
      agr_1016.variant   as Variant,
      agr_1016.generated as Generated,
      agr_1016.pstate    as Version
}
