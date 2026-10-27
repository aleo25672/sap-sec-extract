@AbapCatalog.sqlViewName: 'ZISEC_PROFILE'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Security access profile'
define view ZI_SEC_PROFILE
  as select from usr10
    left outer join usr11 as TextLogon
      on  usr10.profn   = TextLogon.profn
      and usr10.aktps   = TextLogon.aktps
      and TextLogon.langu = $session.system_language
    left outer join usr11 as TextEnglish
      on  usr10.profn     = TextEnglish.profn
      and usr10.aktps     = TextEnglish.aktps
      and TextEnglish.langu = 'E'
{
  key usr10.profn   as ProfileName,
  key usr10.aktps   as Version,
      usr10.typ     as ProfileType,
      usr10.modbe   as ChangedBy,
      usr10.modda   as ChangedOn,
      usr10.modti   as ChangedAt,
      usr10.divis   as Department,
      usr10.nraut   as AuthorizationCount,
      coalesce( TextLogon.ptext, TextEnglish.ptext ) as Description
}
