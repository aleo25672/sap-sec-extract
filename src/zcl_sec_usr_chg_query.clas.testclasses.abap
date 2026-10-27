CLASS ltcl_source DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_sec_access_source.
    DATA called TYPE abap_bool.
    DATA userid_low TYPE string.
    DATA date_low TYPE string.
    DATA changedby_low TYPE string.
ENDCLASS.


CLASS ltcl_source IMPLEMENTATION.
  METHOD zif_sec_access_source~read_users.
    RETURN.
  ENDMETHOD.
  METHOD zif_sec_access_source~read_role_assignments.
    RETURN.
  ENDMETHOD.
  METHOD zif_sec_access_source~read_profile_assignments.
    RETURN.
  ENDMETHOD.
  METHOD zif_sec_access_source~read_roles.
    RETURN.
  ENDMETHOD.
  METHOD zif_sec_access_source~read_role_hierarchy.
    RETURN.
  ENDMETHOD.
  METHOD zif_sec_access_source~read_role_profiles.
    RETURN.
  ENDMETHOD.
  METHOD zif_sec_access_source~read_role_authorizations.
    RETURN.
  ENDMETHOD.
  METHOD zif_sec_access_source~read_role_org_levels.
    RETURN.
  ENDMETHOD.
  METHOD zif_sec_access_source~read_profiles.
    RETURN.
  ENDMETHOD.
  METHOD zif_sec_access_source~read_profile_authorizations.
    RETURN.
  ENDMETHOD.
  METHOD zif_sec_access_source~read_authorization_values.
    RETURN.
  ENDMETHOD.
  METHOD zif_sec_access_source~read_critical_authorizations.
    RETURN.
  ENDMETHOD.
  METHOD zif_sec_access_source~read_critical_variants.
    RETURN.
  ENDMETHOD.
  METHOD zif_sec_access_source~read_user_changes.
    called = abap_true.
    IF lines( it_userid ) > 0.
      userid_low = it_userid[ 1 ]-low.
    ENDIF.
    IF lines( it_changedate ) > 0.
      date_low = it_changedate[ 1 ]-low.
    ENDIF.
    IF lines( it_changedby ) > 0.
      changedby_low = it_changedby[ 1 ]-low.
    ENDIF.
    APPEND VALUE #(
      userid          = 'JSMITH'
      changenumber    = '0000000001'
      changedby       = 'ADMIN'
      changedate      = '20261027'
      changetime      = '101500'
      transactioncode = 'SU01'
      headerchange    = 'U'
      tablename       = 'USR02'
      tablekey        = '100JSMITH'
      fieldname       = 'UFLAG'
      itemchange      = 'U'
      valueold        = '0'
      valuenew        = '64' ) TO rt_rows.
    APPEND VALUE #(
      userid          = 'JSMITH'
      changenumber    = '0000000001'
      changedby       = 'ADMIN'
      changedate      = '20261027'
      changetime      = '101500'
      transactioncode = 'SU01'
      headerchange    = 'U'
      tablename       = 'USR02'
      tablekey        = '100JSMITH'
      fieldname       = 'PWDSALTEDHASH'
      itemchange      = 'U'
      valueold        = 'SECRET-OLD'
      valuenew        = 'SECRET-NEW' ) TO rt_rows.
    APPEND VALUE #(
      userid          = 'JSMITH'
      changenumber    = '0000000002'
      changedby       = 'ADMIN'
      changedate      = '20261027'
      changetime      = '101600'
      transactioncode = 'SU01'
      headerchange    = 'U'
      tablename       = 'ADR6'
      tablekey        = '1000000000001'
      fieldname       = 'SMTP_ADDR'
      itemchange      = 'U'
      valueold        = 'old@example.com'
      valuenew        = 'new@example.com' ) TO rt_rows.
  ENDMETHOD.
ENDCLASS.


CLASS ltcl_deny DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_sec_access_auth.
ENDCLASS.


CLASS ltcl_deny IMPLEMENTATION.
  METHOD zif_sec_access_auth~check_user_display.
    RAISE EXCEPTION TYPE zcx_sec_access
      EXPORTING
        textid = zcx_sec_access=>not_authorized.
  ENDMETHOD.
  METHOD zif_sec_access_auth~check_role_display.
    RAISE EXCEPTION TYPE zcx_sec_access
      EXPORTING
        textid = zcx_sec_access=>not_authorized.
  ENDMETHOD.
  METHOD zif_sec_access_auth~check_profile_display.
    RAISE EXCEPTION TYPE zcx_sec_access
      EXPORTING
        textid = zcx_sec_access=>not_authorized.
  ENDMETHOD.
ENDCLASS.


CLASS ltcl_allow DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_sec_access_auth.
ENDCLASS.


CLASS ltcl_allow IMPLEMENTATION.
  METHOD zif_sec_access_auth~check_user_display.
    RETURN.
  ENDMETHOD.
  METHOD zif_sec_access_auth~check_role_display.
    RETURN.
  ENDMETHOD.
  METHOD zif_sec_access_auth~check_profile_display.
    RETURN.
  ENDMETHOD.
ENDCLASS.


CLASS ltcl_query_auth DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS denied_auth_does_not_read FOR TESTING.
    METHODS blanks_secrets_and_passes_filters FOR TESTING.
    METHODS bad_change_date_does_not_read FOR TESTING.
ENDCLASS.


CLASS ltcl_query_auth IMPLEMENTATION.
  METHOD denied_auth_does_not_read.
    DATA(lo_source) = NEW ltcl_source( ).
    DATA(lo_query) = NEW zcl_sec_usr_chg_query(
      io_source = lo_source
      io_auth   = NEW ltcl_deny( ) ).

    TRY.
        lo_query->read_rows( ).
        cl_abap_unit_assert=>fail( 'Authorization failure must raise' ).
      CATCH zcx_sec_access.
        cl_abap_unit_assert=>assert_false( lo_source->called ).
    ENDTRY.
  ENDMETHOD.

  METHOD blanks_secrets_and_passes_filters.
    DATA(lo_source) = NEW ltcl_source( ).
    DATA(lo_query) = NEW zcl_sec_usr_chg_query(
      io_source = lo_source
      io_auth   = NEW ltcl_allow( ) ).

    DATA(lt_rows) = lo_query->read_rows(
      it_userid     = VALUE #( ( sign = 'I' option = 'EQ' low = 'jsmith' ) )
      it_changedate = VALUE #( ( sign = 'I' option = 'GE' low = '2026-10-27' ) )
      it_changedby  = VALUE #( ( sign = 'I' option = 'EQ' low = 'Admin' ) ) ).

    cl_abap_unit_assert=>assert_true( lo_source->called ).
    cl_abap_unit_assert=>assert_equals( act = lo_source->userid_low exp = 'JSMITH' ).
    cl_abap_unit_assert=>assert_equals( act = lo_source->date_low exp = '20261027' ).
    cl_abap_unit_assert=>assert_equals( act = lo_source->changedby_low exp = 'ADMIN' ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_rows ) exp = 3 ).

    DATA(ls_lock) = lt_rows[ fieldname = 'UFLAG' ].
    cl_abap_unit_assert=>assert_equals( act = condense( ls_lock-valueold ) exp = '0' ).
    cl_abap_unit_assert=>assert_equals( act = condense( ls_lock-valuenew ) exp = '64' ).
    cl_abap_unit_assert=>assert_equals( act = ls_lock-client exp = sy-mandt ).
    cl_abap_unit_assert=>assert_equals( act = condense( ls_lock-changedby ) exp = 'ADMIN' ).

    DATA(ls_hash) = lt_rows[ fieldname = 'PWDSALTEDHASH' ].
    cl_abap_unit_assert=>assert_initial( ls_hash-valueold ).
    cl_abap_unit_assert=>assert_initial( ls_hash-valuenew ).
    cl_abap_unit_assert=>assert_equals( act = condense( ls_hash-fieldname ) exp = 'PWDSALTEDHASH' ).

    DATA(ls_mail) = lt_rows[ tablename = 'ADR6' ].
    cl_abap_unit_assert=>assert_initial( ls_mail-valueold ).
    cl_abap_unit_assert=>assert_initial( ls_mail-valuenew ).
    cl_abap_unit_assert=>assert_equals( act = condense( ls_mail-fieldname ) exp = 'SMTP_ADDR' ).
  ENDMETHOD.

  METHOD bad_change_date_does_not_read.
    DATA(lo_source) = NEW ltcl_source( ).
    DATA(lo_query) = NEW zcl_sec_usr_chg_query(
      io_source = lo_source
      io_auth   = NEW ltcl_allow( ) ).

    TRY.
        lo_query->read_rows( it_changedate = VALUE #( ( sign = 'I' option = 'EQ' low = 'yesterday' ) ) ).
        cl_abap_unit_assert=>fail( 'A change date that is not a date must raise' ).
      CATCH zcx_sec_access.
        cl_abap_unit_assert=>assert_false( lo_source->called ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
