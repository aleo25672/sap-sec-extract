@AbapCatalog.sqlViewName: 'ZISEC_ROLE'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Security access role'
define view ZI_SEC_ROLE
  as select from agr_define
    left outer join agr_texts as TextLogon
      on  agr_define.agr_name = TextLogon.agr_name
      and TextLogon.spras     = $session.system_language
      and TextLogon.line      = '00000'
    left outer join agr_texts as TextEnglish
      on  agr_define.agr_name = TextEnglish.agr_name
      and TextEnglish.spras   = 'E'
      and TextEnglish.line    = '00000'
{
  key agr_define.agr_name  as RoleName,
      agr_define.parent_agr as ParentRole,
      agr_define.create_usr as CreatedBy,
      agr_define.create_dat as CreatedOn,
      agr_define.change_usr as ChangedBy,
      agr_define.change_dat as ChangedOn,
      coalesce( TextLogon.text, TextEnglish.text ) as Description
}
