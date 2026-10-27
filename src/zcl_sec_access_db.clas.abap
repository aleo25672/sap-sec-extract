CLASS zcl_sec_access_db DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_sec_access_source.
ENDCLASS.


CLASS zcl_sec_access_db IMPLEMENTATION.
  METHOD zif_sec_access_source~read_users.
    SELECT userid, usertype, usergroup, validfrom, validto, lockflag,
           passwordstate, passwordhashversion, lastlogondate, lastlogontime,
           createdby, createdon, securitypolicy, referenceuser
      FROM zi_sec_user
      INTO CORRESPONDING FIELDS OF TABLE @rt_rows.
  ENDMETHOD.

  METHOD zif_sec_access_source~read_role_assignments.
    SELECT userid, rolename, validfrom, validto, excluded, changedon,
           fromcompositerole, fromorgmanagement
      FROM zi_sec_role_assign
      INTO CORRESPONDING FIELDS OF TABLE @rt_rows.
  ENDMETHOD.

  METHOD zif_sec_access_source~read_profile_assignments.
    SELECT userid, profilename
      FROM zi_sec_prof_assign
      INTO TABLE @DATA(lt_assigned).
    LOOP AT lt_assigned INTO DATA(ls_assigned).
      APPEND VALUE #(
        userid        = ls_assigned-userid
        profilename   = ls_assigned-profilename
        profilesource = 'Assigned' ) TO rt_rows.
    ENDLOOP.

    SELECT FROM usrefus
      INNER JOIN ust04 ON ust04~bname = usrefus~refuser
      FIELDS usrefus~bname AS userid,
             ust04~profile AS profilename,
             usrefus~refuser AS referenceuser
      INTO TABLE @DATA(lt_reference).
    LOOP AT lt_reference INTO DATA(ls_reference).
      APPEND VALUE #(
        userid         = ls_reference-userid
        profilename    = ls_reference-profilename
        profilesource  = 'ReferenceUser'
        referenceuser  = ls_reference-referenceuser ) TO rt_rows.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_sec_access_source~read_roles.
    SELECT rolename, parentrole, createdby, createdon, changedby, changedon, description
      FROM zi_sec_role
      INTO CORRESPONDING FIELDS OF TABLE @rt_rows.
  ENDMETHOD.

  METHOD zif_sec_access_source~read_role_hierarchy.
    SELECT compositerole, singlerole
      FROM zi_sec_role_hier
      INTO CORRESPONDING FIELDS OF TABLE @rt_rows.
  ENDMETHOD.

  METHOD zif_sec_access_source~read_role_profiles.
    SELECT rolename, counter, profilename, variant, generated, version
      FROM zi_sec_role_profile
      INTO CORRESPONDING FIELDS OF TABLE @rt_rows.
  ENDMETHOD.

  METHOD zif_sec_access_source~read_role_authorizations.
    SELECT rolename, counter, object, authorization, variant, field, low, high,
           modified, deleted, copied, newentry
      FROM zi_sec_role_auth
      INTO CORRESPONDING FIELDS OF TABLE @rt_rows.
  ENDMETHOD.

  METHOD zif_sec_access_source~read_role_org_levels.
    SELECT rolename, counter, variable, low, high
      FROM zi_sec_role_org
      INTO CORRESPONDING FIELDS OF TABLE @rt_rows.
  ENDMETHOD.

  METHOD zif_sec_access_source~read_profiles.
    SELECT profilename, version, profiletype, changedby, changedon, changedat,
           department, authorizationcount, description
      FROM zi_sec_profile
      INTO CORRESPONDING FIELDS OF TABLE @rt_rows.
  ENDMETHOD.

  METHOD zif_sec_access_source~read_profile_authorizations.
    SELECT profilename, version, object, authorization
      FROM zi_sec_prof_auth
      INTO CORRESPONDING FIELDS OF TABLE @rt_rows.
  ENDMETHOD.

  METHOD zif_sec_access_source~read_authorization_values.
    SELECT object, authorization, version, field, low, high
      FROM zi_sec_auth_value
      INTO CORRESPONDING FIELDS OF TABLE @rt_rows.
  ENDMETHOD.

  METHOD zif_sec_access_source~read_critical_authorizations.
    SELECT authorizationid, criticalgroup, object, field, low, high, searchtype,
           color, transactioncode, description
      FROM zi_sec_crit_auth
      INTO CORRESPONDING FIELDS OF TABLE @rt_rows.
  ENDMETHOD.

  METHOD zif_sec_access_source~read_critical_variants.
    SELECT variantname, authorizationid
      FROM zi_sec_crit_var
      INTO CORRESPONDING FIELDS OF TABLE @rt_rows.
  ENDMETHOD.
ENDCLASS.
