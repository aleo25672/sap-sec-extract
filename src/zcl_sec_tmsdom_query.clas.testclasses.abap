CLASS ltcl_deny_admin DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_sec_auth.
ENDCLASS.

CLASS ltcl_deny_admin IMPLEMENTATION.
  METHOD zif_sec_auth~check_profile_display.
  ENDMETHOD.
  METHOD zif_sec_auth~check_policy_display.
  ENDMETHOD.
  METHOD zif_sec_auth~check_client_display.
  ENDMETHOD.
  METHOD zif_sec_auth~check_system_change_display.
  ENDMETHOD.
  METHOD zif_sec_auth~check_system_display.
  ENDMETHOD.
  METHOD zif_sec_auth~check_named_table.
  ENDMETHOD.
  METHOD zif_sec_auth~check_batch_input_display.
  ENDMETHOD.
  METHOD zif_sec_auth~check_transport_admin.
    RAISE EXCEPTION TYPE zcx_sec_settings
      EXPORTING
        textid = zcx_sec_settings=>not_authorized.
  ENDMETHOD.
  METHOD zif_sec_auth~check_transport_display.
  ENDMETHOD.
  METHOD zif_sec_auth~can_count_users.
    rv_yes = abap_false.
  ENDMETHOD.
ENDCLASS.

CLASS ltcl_tmsdom_auth DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS denied_admin_does_not_read FOR TESTING.
ENDCLASS.

CLASS ltcl_tmsdom_auth IMPLEMENTATION.
  METHOD denied_admin_does_not_read.
    DATA lv_raised TYPE abap_bool.
    TRY.
        NEW zcl_sec_tmsdom_query( io_auth = NEW ltcl_deny_admin( ) )->read_rows( ).
      CATCH zcx_sec_settings.
        lv_raised = abap_true.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( lv_raised ).
  ENDMETHOD.
ENDCLASS.
