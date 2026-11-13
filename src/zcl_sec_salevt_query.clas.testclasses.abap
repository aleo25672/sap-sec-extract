CLASS ltcl_deny_salevt DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_sec_access_auth.
ENDCLASS.

CLASS ltcl_deny_salevt IMPLEMENTATION.
  METHOD zif_sec_access_auth~check_user_display.
  ENDMETHOD.
  METHOD zif_sec_access_auth~check_role_display.
  ENDMETHOD.
  METHOD zif_sec_access_auth~check_profile_display.
  ENDMETHOD.
  METHOD zif_sec_access_auth~check_audit_display.
    RAISE EXCEPTION TYPE zcx_sec_access
      EXPORTING
        textid = zcx_sec_access=>not_authorized.
  ENDMETHOD.
  METHOD zif_sec_access_auth~check_system_log_display.
  ENDMETHOD.
ENDCLASS.

CLASS ltcl_salevt_auth DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS denied_audit_does_not_read FOR TESTING.
    METHODS file_record_keeps_the_event FOR TESTING.
ENDCLASS.

CLASS ltcl_salevt_auth IMPLEMENTATION.
  METHOD denied_audit_does_not_read.
    DATA lv_raised TYPE abap_bool.
    TRY.
        NEW zcl_sec_salevt_query( io_auth = NEW ltcl_deny_salevt( ) )->read_rows( ).
      CATCH zcx_sec_access.
        lv_raised = abap_true.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( lv_raised ).
  ENDMETHOD.

  METHOD file_record_keeps_the_event.
    DATA ls_entry TYPE rsauentr2.
    ls_entry-slgdattim = '2026110321205200'.
    ls_entry-slgmand = '100'.
    ls_entry-slguser = 'ARIA'.
    ls_entry-slgtc = 'SE37'.
    ls_entry-slgrepna = 'RS_TESTFRAME_CALL'.
    ls_entry-slgltrm2 = '99.119.193.165'.
    ls_entry-slgdata = 'BAPI_COMPANYCODE_GETLIST'.
    DATA ls_file TYPE rsauetab2.
    ls_file-area = 'FU'.
    ls_file-subid = 'J'.
    ls_file-sender_id = 'vhcals4hci_S4H_00'.
    ls_file-centdata = ls_entry.
    DATA(ls_row) = zcl_sec_salevt_query=>file_event( is_file = ls_file iv_system = 'S4H' ).
    cl_abap_unit_assert=>assert_equals( act = ls_row-messageid exp = 'FUJ' ).
    cl_abap_unit_assert=>assert_equals( act = ls_row-eventon exp = '20261103' ).
    cl_abap_unit_assert=>assert_equals( act = ls_row-client exp = '100' ).
    cl_abap_unit_assert=>assert_equals( act = ls_row-username exp = 'ARIA' ).
    cl_abap_unit_assert=>assert_equals( act = ls_row-transactioncode exp = 'SE37' ).
    cl_abap_unit_assert=>assert_equals( act = ls_row-instancename exp = 'vhcals4hci_S4H_00' ).
    cl_abap_unit_assert=>assert_equals( act = ls_row-systemid exp = 'S4H' ).
  ENDMETHOD.
ENDCLASS.
