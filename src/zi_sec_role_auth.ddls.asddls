@AbapCatalog.sqlViewName: 'ZISEC_ROLE_AUTH'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Security access role authorization'
define view ZI_SEC_ROLE_AUTH
  as select from agr_1251
{
  key agr_1251.agr_name as RoleName,
  key agr_1251.counter  as Counter,
      agr_1251.object   as Object,
      agr_1251.auth     as AuthName,
      agr_1251.variant  as Variant,
      agr_1251.field    as Field,
      agr_1251.low      as Low,
      agr_1251.high     as High,
      agr_1251.modified as Modified,
      agr_1251.deleted  as Deleted,
      agr_1251.copied   as Copied,
      agr_1251.neu      as NewEntry
}
