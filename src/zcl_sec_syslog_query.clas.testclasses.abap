CLASS ltcl_deny_syslog DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_sec_access_auth.
ENDCLASS.

CLASS ltcl_deny_syslog IMPLEMENTATION.
  METHOD zif_sec_access_auth~check_user_display.
  ENDMETHOD.
  METHOD zif_sec_access_auth~check_role_display.
  ENDMETHOD.
  METHOD zif_sec_access_auth~check_profile_display.
  ENDMETHOD.
  METHOD zif_sec_access_auth~check_audit_display.
  ENDMETHOD.
  METHOD zif_sec_access_auth~check_system_log_display.
    RAISE EXCEPTION TYPE zcx_sec_access
      EXPORTING
        textid = zcx_sec_access=>not_authorized.
  ENDMETHOD.
ENDCLASS.

CLASS ltcl_syslog_auth DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS denied_log_does_not_read FOR TESTING.
ENDCLASS.

CLASS ltcl_syslog_auth IMPLEMENTATION.
  METHOD denied_log_does_not_read.
    DATA lv_raised TYPE abap_bool.
    TRY.
        NEW zcl_sec_syslog_query( io_auth = NEW ltcl_deny_syslog( ) )->read_rows( ).
      CATCH zcx_sec_access.
        lv_raised = abap_true.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( lv_raised ).
  ENDMETHOD.
ENDCLASS.
