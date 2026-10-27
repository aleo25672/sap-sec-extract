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
      excluded             TYPE agr_users-exclude,
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
    tt_role_hierarchy TYPE STANDARD TABLE OF ty_role_hierarchy WITH EMPTY KEY,
    BEGIN OF ty_role_profile,
      rolename    TYPE agr_1016-agr_name,
      counter     TYPE agr_1016-counter,
      profilename TYPE agr_1016-profile,
      variant     TYPE agr_1016-variant,
      generated   TYPE agr_1016-generated,
      version     TYPE agr_1016-pstate,
    END OF ty_role_profile,
    tt_role_profile TYPE STANDARD TABLE OF ty_role_profile WITH EMPTY KEY,
    BEGIN OF ty_role_authorization,
      rolename      TYPE agr_1251-agr_name,
      counter       TYPE agr_1251-counter,
      object        TYPE agr_1251-object,
      authname      TYPE agr_1251-auth,
      variant       TYPE agr_1251-variant,
      field         TYPE agr_1251-field,
      low           TYPE agr_1251-low,
      high          TYPE agr_1251-high,
      modified      TYPE agr_1251-modified,
      deleted       TYPE agr_1251-deleted,
      copied        TYPE agr_1251-copied,
      newentry      TYPE agr_1251-neu,
    END OF ty_role_authorization,
    tt_role_authorization TYPE STANDARD TABLE OF ty_role_authorization WITH EMPTY KEY,
    BEGIN OF ty_role_org_level,
      rolename TYPE agr_1252-agr_name,
      counter  TYPE agr_1252-counter,
      orglevel TYPE agr_1252-varbl,
      low      TYPE agr_1252-low,
      high     TYPE agr_1252-high,
    END OF ty_role_org_level,
    tt_role_org_level TYPE STANDARD TABLE OF ty_role_org_level WITH EMPTY KEY,
    BEGIN OF ty_profile,
      profilename          TYPE usr10-profn,
      version              TYPE usr10-aktps,
      profiletype          TYPE usr10-typ,
      changedby            TYPE usr10-modbe,
      changedon            TYPE usr10-modda,
      changedat            TYPE usr10-modti,
      department           TYPE usr10-divis,
      authorizationcount   TYPE usr10-nraut,
      description          TYPE usr11-ptext,
    END OF ty_profile,
    tt_profile TYPE STANDARD TABLE OF ty_profile WITH EMPTY KEY,
    BEGIN OF ty_profile_authorization,
      profilename   TYPE ust10s-profn,
      version       TYPE ust10s-aktps,
      object        TYPE ust10s-objct,
      authname      TYPE ust10s-auth,
    END OF ty_profile_authorization,
    tt_profile_authorization TYPE STANDARD TABLE OF ty_profile_authorization WITH EMPTY KEY,
    BEGIN OF ty_authorization_value,
      object        TYPE ust12-objct,
      authname      TYPE ust12-auth,
      version       TYPE ust12-aktps,
      field         TYPE ust12-field,
      low           TYPE ust12-von,
      high          TYPE ust12-bis,
    END OF ty_authorization_value,
    tt_authorization_value TYPE STANDARD TABLE OF ty_authorization_value WITH EMPTY KEY,
    BEGIN OF ty_critical_authorization,
      authorizationid TYPE uscrauth-auth_id,
      criticalgroup   TYPE uscrauth-cr_auth,
      object          TYPE uscrauth-objct,
      field           TYPE uscrauth-field,
      low             TYPE uscrauth-low,
      high            TYPE uscrauth-high,
      searchtype      TYPE uscrauth-searchtype,
      color           TYPE uscrauthid-auth_color,
      transactioncode TYPE uscrauthid-tcode,
      description     TYPE uscrauidt-text,
    END OF ty_critical_authorization,
    tt_critical_authorization TYPE STANDARD TABLE OF ty_critical_authorization WITH EMPTY KEY,
    BEGIN OF ty_critical_variant,
      variantname     TYPE usrvarid-varname,
      authorizationid TYPE usrvarid-auth_id,
    END OF ty_critical_variant,
    tt_critical_variant TYPE STANDARD TABLE OF ty_critical_variant WITH EMPTY KEY,
    BEGIN OF ty_user_change,
      userid          TYPE cdhdr-objectid,
      changenumber    TYPE cdhdr-changenr,
      changedby       TYPE cdhdr-username,
      changedate      TYPE cdhdr-udate,
      changetime      TYPE cdhdr-utime,
      transactioncode TYPE cdhdr-tcode,
      headerchange    TYPE cdhdr-change_ind,
      tablename       TYPE cdpos-tabname,
      tablekey        TYPE cdpos-tabkey,
      fieldname       TYPE cdpos-fname,
      itemchange      TYPE cdpos-chngind,
      valueold        TYPE cdpos-value_old,
      valuenew        TYPE cdpos-value_new,
    END OF ty_user_change,
    tt_user_change TYPE STANDARD TABLE OF ty_user_change WITH EMPTY KEY,
    BEGIN OF ty_role_change,
      rolename        TYPE cdhdr-objectid,
      changenumber    TYPE cdhdr-changenr,
      changedby       TYPE cdhdr-username,
      changedate      TYPE cdhdr-udate,
      changetime      TYPE cdhdr-utime,
      transactioncode TYPE cdhdr-tcode,
      headerchange    TYPE cdhdr-change_ind,
      tablename       TYPE cdpos-tabname,
      tablekey        TYPE cdpos-tabkey,
      fieldname       TYPE cdpos-fname,
      itemchange      TYPE cdpos-chngind,
      valueold        TYPE cdpos-value_old,
      valuenew        TYPE cdpos-value_new,
    END OF ty_role_change,
    tt_role_change TYPE STANDARD TABLE OF ty_role_change WITH EMPTY KEY.

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

  METHODS read_role_profiles
    RETURNING VALUE(rt_rows) TYPE tt_role_profile.

  METHODS read_role_authorizations
    RETURNING VALUE(rt_rows) TYPE tt_role_authorization.

  METHODS read_role_org_levels
    RETURNING VALUE(rt_rows) TYPE tt_role_org_level.

  METHODS read_profiles
    RETURNING VALUE(rt_rows) TYPE tt_profile.

  METHODS read_profile_authorizations
    RETURNING VALUE(rt_rows) TYPE tt_profile_authorization.

  METHODS read_authorization_values
    RETURNING VALUE(rt_rows) TYPE tt_authorization_value.

  METHODS read_critical_authorizations
    RETURNING VALUE(rt_rows) TYPE tt_critical_authorization.

  METHODS read_critical_variants
    RETURNING VALUE(rt_rows) TYPE tt_critical_variant.

  METHODS read_user_changes
    IMPORTING
      it_userid     TYPE zcl_sec_query_util=>tt_range
      it_changedate TYPE zcl_sec_query_util=>tt_range
      it_changedby  TYPE zcl_sec_query_util=>tt_range
    RETURNING
      VALUE(rt_rows) TYPE tt_user_change
    RAISING
      zcx_sec_access.

  METHODS read_role_changes
    IMPORTING
      it_rolename   TYPE zcl_sec_query_util=>tt_range
      it_changedate TYPE zcl_sec_query_util=>tt_range
      it_changedby  TYPE zcl_sec_query_util=>tt_range
    RETURNING
      VALUE(rt_rows) TYPE tt_role_change
    RAISING
      zcx_sec_access.
ENDINTERFACE.
