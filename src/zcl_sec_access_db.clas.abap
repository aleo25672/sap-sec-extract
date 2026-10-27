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
    SELECT rolename, counter, object, authname, variant, field, low, high,
           modified, deleted, copied, newentry
      FROM zi_sec_role_auth
      INTO CORRESPONDING FIELDS OF TABLE @rt_rows.
  ENDMETHOD.

  METHOD zif_sec_access_source~read_role_org_levels.
    SELECT rolename, counter, orglevel, low, high
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
    SELECT profilename, version, object, authname
      FROM zi_sec_prof_auth
      INTO CORRESPONDING FIELDS OF TABLE @rt_rows.
  ENDMETHOD.

  METHOD zif_sec_access_source~read_authorization_values.
    SELECT object, authname, version, field, low, high
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

  METHOD zif_sec_access_source~read_user_changes.
    DATA lr_user TYPE RANGE OF cdhdr-objectid.
    DATA lr_date TYPE RANGE OF cdhdr-udate.
    DATA lr_by TYPE RANGE OF cdhdr-username.
    DATA ls_date_range LIKE LINE OF lr_date.

    LOOP AT it_userid INTO DATA(ls_user).
      APPEND VALUE #(
        sign   = to_upper( ls_user-sign )
        option = to_upper( ls_user-option )
        low    = to_upper( ls_user-low )
        high   = to_upper( ls_user-high ) ) TO lr_user.
    ENDLOOP.
    LOOP AT it_changedby INTO DATA(ls_by).
      APPEND VALUE #(
        sign   = to_upper( ls_by-sign )
        option = to_upper( ls_by-option )
        low    = to_upper( ls_by-low )
        high   = to_upper( ls_by-high ) ) TO lr_by.
    ENDLOOP.
    LOOP AT it_changedate INTO DATA(ls_date).
      CLEAR ls_date_range.
      ls_date_range-sign = to_upper( ls_date-sign ).
      ls_date_range-option = to_upper( ls_date-option ).
      TRY.
          IF ls_date-low IS NOT INITIAL.
            ls_date_range-low = ls_date-low.
          ENDIF.
          IF ls_date-high IS NOT INITIAL.
            ls_date_range-high = ls_date-high.
          ENDIF.
        CATCH cx_sy_conversion_error INTO DATA(lx_date).
          RAISE EXCEPTION TYPE zcx_sec_access
            EXPORTING
              textid      = zcx_sec_access=>filter_not_supported
              previous    = lx_date
              filter_name = 'ChangeDate'.
      ENDTRY.
      APPEND ls_date_range TO lr_date.
    ENDLOOP.

    " An empty range adds no restriction. The view blanks password and address values.
    SELECT userid, changenumber, changedby, changedate, changetime, transactioncode,
           headerchange, tablename, tablekey, fieldname, itemchange, valueold, valuenew
      FROM zi_sec_usr_chg
      WHERE userid IN @lr_user
        AND changedate IN @lr_date
        AND changedby IN @lr_by
      INTO CORRESPONDING FIELDS OF TABLE @rt_rows.

    LOOP AT rt_rows ASSIGNING FIELD-SYMBOL(<ls_row>).
      <ls_row>-valueold = zcl_sec_usr_chg_guard=>payload_value(
        iv_table = <ls_row>-tablename
        iv_field = <ls_row>-fieldname
        iv_value = <ls_row>-valueold ).
      <ls_row>-valuenew = zcl_sec_usr_chg_guard=>payload_value(
        iv_table = <ls_row>-tablename
        iv_field = <ls_row>-fieldname
        iv_value = <ls_row>-valuenew ).
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
