@AbapCatalog.sqlViewName: 'ZISEC_ROLE_HIER'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Security access role hierarchy'
define view ZI_SEC_ROLE_HIER
  as select from agr_agrs
{
  key agr_agrs.agr_name  as CompositeRole,
  key agr_agrs.child_agr as SingleRole
}
