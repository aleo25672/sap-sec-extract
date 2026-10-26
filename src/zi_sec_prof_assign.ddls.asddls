@AbapCatalog.sqlViewName: 'ZISEC_PROF_ASGN'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Security access profile assignment'
define view ZI_SEC_PROF_ASSIGN
  as select from ust04
{
  key ust04.bname                         as UserId,
  key ust04.profile                       as ProfileName,
  key cast( 'Assigned' as abap.char(13) ) as ProfileSource,
      cast( '' as xubname )               as ReferenceUser
}
union all
select from usrefus
  inner join ust04 as ReferenceProfile
    on usrefus.refuser = ReferenceProfile.bname
{
  key usrefus.bname                              as UserId,
  key ReferenceProfile.profile                   as ProfileName,
  key cast( 'ReferenceUser' as abap.char(13) )   as ProfileSource,
      usrefus.refuser                            as ReferenceUser
}
