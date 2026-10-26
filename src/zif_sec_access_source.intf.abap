INTERFACE zif_sec_access_source
  PUBLIC.

  TYPES:
    BEGIN OF ty_user,
      userid                TYPE usr02-bname,
      usertype              TYPE usr02-ustyp,
      usergroup             TYPE usr02-class,
      validfrom             TYPE usr02-gltgv,
      validto               TYPE usr02-gltgb,
      lockflag              TYPE usr02-uflag,
      passwordstate         TYPE usr02-pwdstate,
      passwordhashversion   TYPE usr02-codvn,
      lastlogondate         TYPE usr02-trdat,
      lastlogontime         TYPE usr02-ltime,
      createdby             TYPE usr02-aname,
      createdon             TYPE usr02-erdat,
      securitypolicy        TYPE usr02-security_policy,
      referenceuser         TYPE usrefus-refuser,
    END OF ty_user,
    tt_user TYPE STANDARD TABLE OF ty_user WITH EMPTY KEY,
    BEGIN OF ty_role_assignment,
      userid               TYPE agr_users-uname,
      rolename             TYPE agr_users-agr_name,
      validfrom            TYPE agr_users-from_dat,
      validto              TYPE agr_users-to_dat,
      exclusive            TYPE agr_users-exclude,
      changedon            TYPE agr_users-change_dat,
      fromcompositerole    TYPE agr_users-col_flag,
      fromorgmanagement    TYPE agr_users-org_flag,
    END OF ty_role_assignment,
    tt_role_assignment TYPE STANDARD TABLE OF ty_role_assignment WITH EMPTY KEY,
    BEGIN OF ty_profile_assignment,
      userid          TYPE ust04-bname,
      profilename     TYPE ust04-profile,
      profilesource   TYPE c LENGTH 13,
      referenceuser   TYPE usrefus-refuser,
    END OF ty_profile_assignment,
    tt_profile_assignment TYPE STANDARD TABLE OF ty_profile_assignment WITH EMPTY KEY,
    BEGIN OF ty_role,
      rolename    TYPE agr_define-agr_name,
      parentrole  TYPE agr_define-parent_agr,
      createdby   TYPE agr_define-create_usr,
      createdon   TYPE agr_define-create_dat,
      changedby   TYPE agr_define-change_usr,
      changedon   TYPE agr_define-change_dat,
      description TYPE agr_texts-text,
    END OF ty_role,
    tt_role TYPE STANDARD TABLE OF ty_role WITH EMPTY KEY,
    BEGIN OF ty_role_hierarchy,
      compositerole TYPE agr_agrs-agr_name,
      singlerole    TYPE agr_agrs-child_agr,
    END OF ty_role_hierarchy,
    tt_role_hierarchy TYPE STANDARD TABLE OF ty_role_hierarchy WITH EMPTY KEY.

  METHODS read_users
    RETURNING VALUE(rt_rows) TYPE tt_user.

  METHODS read_role_assignments
    RETURNING VALUE(rt_rows) TYPE tt_role_assignment.

  METHODS read_profile_assignments
    RETURNING VALUE(rt_rows) TYPE tt_profile_assignment.

  METHODS read_roles
    RETURNING VALUE(rt_rows) TYPE tt_role.

  METHODS read_role_hierarchy
    RETURNING VALUE(rt_rows) TYPE tt_role_hierarchy.
ENDINTERFACE.
