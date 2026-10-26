@EndUserText.label: 'Security access user'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_USER_QUERY'
define custom entity ZC_SEC_USER
{
  key UserId                   : abap.char(12);
      Client                   : abap.clnt;
      UserType                 : abap.char(1);
      UserTypeText             : abap.char(60);
      UserGroup                : abap.char(12);
      ValidFrom                : abap.dats;
      ValidTo                  : abap.dats;
      LockFlag                 : abap.int4;
      GloballyLocked           : abap.char(1);
      LocallyLocked            : abap.char(1);
      FailedLogonLocked        : abap.char(1);
      PasswordState            : abap.int4;
      PasswordStateText        : abap.char(80);
      PasswordHashVersion      : abap.char(1);
      PasswordHashVersionText  : abap.char(40);
      LastLogonDate            : abap.dats;
      LastLogonTime            : abap.tims;
      CreatedBy                : abap.char(12);
      CreatedOn                : abap.dats;
      SecurityPolicy           : abap.char(40);
      ReferenceUser            : abap.char(12);
}
