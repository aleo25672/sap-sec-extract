@AbapCatalog.sqlViewName: 'ZISEC_ROLE_ORG'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Security access role org level'
define view ZI_SEC_ROLE_ORG
  as select from agr_1252
{
  key agr_1252.agr_name as RoleName,
  key agr_1252.counter  as Counter,
      agr_1252.varbl    as OrgLevel,
      agr_1252.low      as Low,
      agr_1252.high     as High
}
