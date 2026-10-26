@AbapCatalog.sqlViewName: 'ZISEC_PROF_ASGN'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Security access profile assignment'
define view ZI_SEC_PROF_ASSIGN
  as select from ust04
{
  key ust04.bname   as UserId,
  key ust04.profile as ProfileName
}
