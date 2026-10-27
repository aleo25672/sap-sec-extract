CLASS ltcl_source DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_sec_access_source.
    DATA called TYPE abap_bool.
    DATA rolename_low TYPE string.
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
    RETURN.
  ENDMETHOD.
  METHOD zif_sec_access_source~read_role_changes.
    called = abap_true.
    IF lines( it_rolename ) > 0.
      rolename_low = it_rolename[ 1 ]-low.
    ENDIF.
    IF lines( it_changedate ) > 0.
      date_low = it_changedate[ 1 ]-low.
    ENDIF.
    IF lines( it_changedby ) > 0.
      changedby_low = it_changedby[ 1 ]-low.
    ENDIF.
    APPEND VALUE #(
      rolename        = 'Z_FI_DISPLAY'
      changenumber    = '0000000100'
      changedby       = 'ADMIN'
      changedate      = '20261027'
      changetime      = '111500'
      transactioncode = 'PFCG'
      headerchange    = 'U'
      tablename       = 'AGR_USERS'
      tablekey        = '100Z_FI_DISPLAYJSMITH'
      fieldname       = 'UNAME'
      itemchange      = 'I'
      valueold        = ''
      valuenew        = 'JSMITH' ) TO rt_rows.
    APPEND VALUE #(
      rolename        = 'Z_FI_DISPLAY'
      changenumber    = '0000000100'
      changedby       = 'ADMIN'
      changedate      = '20261027'
      changetime      = '111500'
      transactioncode = 'PFCG'
      headerchange    = 'U'
      tablename       = 'AGR_USERS'
      tablekey        = '100Z_FI_DISPLAYJSMITH'
      fieldname       = 'KEY'
      itemchange      = 'I'
      valueold        = ''
      valuenew        = 'JSMITH' ) TO rt_rows.
    APPEND VALUE #(
      rolename        = 'Z_FI_DISPLAY'
      changenumber    = '0000000101'
      changedby       = 'ADMIN'
      changedate      = '20261027'
      changetime      = '111600'
      transactioncode = 'PFCG'
      headerchange    = 'U'
      tablename       = 'AGR_1251'
      tablekey        = '100Z_FI_DISPLAY'
      fieldname       = 'PWDSALTEDHASH'
      itemchange      = 'U'
      valueold        = 'SECRET-OLD'
      valuenew        = 'SECRET-NEW' ) TO rt_rows.
    APPEND VALUE #(
      rolename        = 'Z_FI_DISPLAY'
      changenumber    = '0000000102'
      changedby       = 'ADMIN'
      changedate      = '20261027'
      changetime      = '111700'
      transactioncode = 'PFCG'
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
    METHODS keeps_assignment_and_blanks_secrets FOR TESTING.
    METHODS bad_change_date_does_not_read FOR TESTING.
ENDCLASS.


CLASS ltcl_query_auth IMPLEMENTATION.
  METHOD denied_auth_does_not_read.
    DATA(lo_source) = NEW ltcl_source( ).
    DATA(lo_query) = NEW zcl_sec_role_chg_query(
      io_source = lo_source
      io_auth   = NEW ltcl_deny( ) ).

    TRY.
        lo_query->read_rows( ).
        cl_abap_unit_assert=>fail( 'Authorization failure must raise' ).
      CATCH zcx_sec_access.
        cl_abap_unit_assert=>assert_false( lo_source->called ).
    ENDTRY.
  ENDMETHOD.

  METHOD keeps_assignment_and_blanks_secrets.
    DATA(lo_source) = NEW ltcl_source( ).
    DATA(lo_query) = NEW zcl_sec_role_chg_query(
      io_source = lo_source
      io_auth   = NEW ltcl_allow( ) ).

    DATA(lt_rows) = lo_query->read_rows(
      it_rolename   = VALUE #( ( sign = 'I' option = 'EQ' low = 'z_fi_display' ) )
      it_changedate = VALUE #( ( sign = 'I' option = 'GE' low = '2026-10-27' ) )
      it_changedby  = VALUE #( ( sign = 'I' option = 'EQ' low = 'Admin' ) ) ).

    cl_abap_unit_assert=>assert_true( lo_source->called ).
    cl_abap_unit_assert=>assert_equals( act = lo_source->rolename_low exp = 'Z_FI_DISPLAY' ).
    cl_abap_unit_assert=>assert_equals( act = lo_source->date_low exp = '20261027' ).
    cl_abap_unit_assert=>assert_equals( act = lo_source->changedby_low exp = 'ADMIN' ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_rows ) exp = 4 ).

    DATA(ls_user) = lt_rows[ fieldname = 'UNAME' ].
    cl_abap_unit_assert=>assert_equals( act = condense( ls_user-valuenew ) exp = 'JSMITH' ).
    cl_abap_unit_assert=>assert_equals( act = ls_user-client exp = sy-mandt ).
    cl_abap_unit_assert=>assert_equals( act = condense( ls_user-changedby ) exp = 'ADMIN' ).
    cl_abap_unit_assert=>assert_equals( act = condense( ls_user-itemchange ) exp = 'I' ).

    DATA(ls_key) = lt_rows[ fieldname = 'KEY' ].
    cl_abap_unit_assert=>assert_equals( act = condense( ls_key-valuenew ) exp = 'JSMITH' ).

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
    DATA(lo_query) = NEW zcl_sec_role_chg_query(
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
