@AbapCatalog.sqlViewName: 'ZISEC_PROF_AUTH'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Security access profile authorization'
define view ZI_SEC_PROF_AUTH
  as select from ust10s
{
  key ust10s.profn as ProfileName,
  key ust10s.aktps as Version,
  key ust10s.objct as Object,
  key ust10s.auth  as Authorization
}
