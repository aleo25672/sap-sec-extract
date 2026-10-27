@AbapCatalog.sqlViewName: 'ZISEC_CRIT_VAR'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Security access critical variant'
define view ZI_SEC_CRIT_VAR
  as select from usrvarid
{
  key usrvarid.varname as VariantName,
  key usrvarid.auth_id as AuthorizationId
}
