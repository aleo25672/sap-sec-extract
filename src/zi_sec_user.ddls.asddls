@AbapCatalog.sqlViewName: 'ZISEC_USER'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Security access user'
define view ZI_SEC_USER
  as select from usr02
    left outer join usrefus on usr02.bname = usrefus.bname
{
  key usr02.bname           as UserId,
      usr02.ustyp           as UserType,
      usr02.class           as UserGroup,
      usr02.gltgv           as ValidFrom,
      usr02.gltgb           as ValidTo,
      usr02.uflag           as LockFlag,
      usr02.pwdstate        as PasswordState,
      usr02.codvn           as PasswordHashVersion,
      usr02.trdat           as LastLogonDate,
      usr02.ltime           as LastLogonTime,
      usr02.aname           as CreatedBy,
      usr02.erdat           as CreatedOn,
      usr02.security_policy as SecurityPolicy,
      usrefus.refuser       as ReferenceUser
}
