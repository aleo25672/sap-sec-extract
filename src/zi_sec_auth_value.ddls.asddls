@AbapCatalog.sqlViewName: 'ZISEC_AUTH_VALUE'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Security access authorization value'
define view ZI_SEC_AUTH_VALUE
  as select from ust12
{
  key ust12.objct as Object,
  key ust12.auth  as Authorization,
  key ust12.aktps as Version,
  key ust12.field as Field,
  key ust12.von   as Low,
  key ust12.bis   as High
}
