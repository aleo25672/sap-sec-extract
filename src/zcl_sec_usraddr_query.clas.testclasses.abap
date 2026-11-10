CLASS ltcl_deny_address DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_sec_access_auth.
ENDCLASS.

CLASS ltcl_deny_address IMPLEMENTATION.
  METHOD zif_sec_access_auth~check_user_display.
    RAISE EXCEPTION TYPE zcx_sec_access
      EXPORTING
        textid = zcx_sec_access=>not_authorized.
  ENDMETHOD.
  METHOD zif_sec_access_auth~check_role_display.
  ENDMETHOD.
  METHOD zif_sec_access_auth~check_profile_display.
  ENDMETHOD.
  METHOD zif_sec_access_auth~check_audit_display.
  ENDMETHOD.
  METHOD zif_sec_access_auth~check_system_log_display.
  ENDMETHOD.
ENDCLASS.

CLASS ltcl_address_choice DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS denied_user_does_not_read FOR TESTING.
    METHODS standard_email_wins FOR TESTING.
ENDCLASS.

CLASS ltcl_address_choice IMPLEMENTATION.
  METHOD denied_user_does_not_read.
    DATA lv_raised TYPE abap_bool.
    TRY.
        NEW zcl_sec_usraddr_query( io_auth = NEW ltcl_deny_address( ) )->read_rows( ).
      CATCH zcx_sec_access.
        lv_raised = abap_true.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( lv_raised ).
  ENDMETHOD.

  METHOD standard_email_wins.
    DATA(ls_current) = VALUE zcl_sec_usraddr_query=>ty_best(
      username  = 'JSMITH'
      preferred = abap_false
      date_from = '20260101'
      row       = VALUE #( username = 'JSMITH' emailaddress = 'old@example.com' ) ).
    DATA(ls_standard) = VALUE zcl_sec_usraddr_query=>ty_best(
      username  = 'JSMITH'
      preferred = abap_true
      date_from = '20200101'
      row       = VALUE #( username = 'JSMITH' emailaddress = 'current@example.com' ) ).
    cl_abap_unit_assert=>assert_true(
      zcl_sec_usraddr_query=>prefer( is_current = ls_current is_candidate = ls_standard ) ).
    cl_abap_unit_assert=>assert_false(
      zcl_sec_usraddr_query=>prefer( is_current = ls_standard is_candidate = ls_current ) ).
  ENDMETHOD.
ENDCLASS.
