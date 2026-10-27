@AbapCatalog.sqlViewName: 'ZISEC_CRIT_AUTH'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Security access critical authorization'
define view ZI_SEC_CRIT_AUTH
  as select from uscrauth
    left outer join uscrauthid
      on uscrauth.auth_id = uscrauthid.auth_id
    left outer join uscrauidt as TextLogon
      on  uscrauth.auth_id = TextLogon.auth_id
      and TextLogon.langu  = $session.system_language
    left outer join uscrauidt as TextEnglish
      on  uscrauth.auth_id   = TextEnglish.auth_id
      and TextEnglish.langu  = 'E'
{
  key uscrauth.auth_id     as AuthorizationId,
  key uscrauth.cr_auth     as CriticalGroup,
  key uscrauth.objct       as Object,
  key uscrauth.field       as Field,
  key uscrauth.low         as Low,
  key uscrauth.high        as High,
      uscrauth.searchtype  as SearchType,
      uscrauthid.auth_color as Color,
      uscrauthid.tcode     as TransactionCode,
      coalesce( TextLogon.text, TextEnglish.text ) as Description
}
