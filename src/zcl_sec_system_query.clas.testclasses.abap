CLASS ltcl_deny_system DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_sec_auth.
ENDCLASS.

CLASS ltcl_deny_system IMPLEMENTATION.
  METHOD zif_sec_auth~check_profile_display.
  ENDMETHOD.
  METHOD zif_sec_auth~check_policy_display.
  ENDMETHOD.
  METHOD zif_sec_auth~check_client_display.
  ENDMETHOD.
  METHOD zif_sec_auth~check_system_change_display.
  ENDMETHOD.
  METHOD zif_sec_auth~check_system_display.
    RAISE EXCEPTION TYPE zcx_sec_settings
      EXPORTING
        textid = zcx_sec_settings=>not_authorized.
  ENDMETHOD.
  METHOD zif_sec_auth~check_named_table.
  ENDMETHOD.
  METHOD zif_sec_auth~check_batch_input_display.
  ENDMETHOD.
  METHOD zif_sec_auth~check_transport_admin.
  ENDMETHOD.
  METHOD zif_sec_auth~check_transport_display.
  ENDMETHOD.
  METHOD zif_sec_auth~can_count_users.
    rv_yes = abap_false.
  ENDMETHOD.
ENDCLASS.

CLASS ltcl_system_source DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_sec_system_source.
    DATA status_called TYPE abap_bool.
    DATA kernel_called TYPE abap_bool.
ENDCLASS.

CLASS ltcl_system_source IMPLEMENTATION.
  METHOD zif_sec_system_source~read_status.
    status_called = abap_true.
  ENDMETHOD.
  METHOD zif_sec_system_source~read_kernel.
    kernel_called = abap_true.
  ENDMETHOD.
ENDCLASS.

CLASS ltcl_system_auth DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS denied_status_does_not_read FOR TESTING.
    METHODS denied_kernel_does_not_read FOR TESTING.
ENDCLASS.

CLASS ltcl_system_auth IMPLEMENTATION.
  METHOD denied_status_does_not_read.
    DATA(lo_source) = NEW ltcl_system_source( ).
    DATA(lo_query) = NEW zcl_sec_system_query(
      io_source = lo_source
      io_auth   = NEW ltcl_deny_system( ) ).

    TRY.
        lo_query->read_rows( ).
        cl_abap_unit_assert=>fail( 'Authorization failure must raise' ).
      CATCH zcx_sec_settings.
        cl_abap_unit_assert=>assert_false( lo_source->status_called ).
    ENDTRY.
  ENDMETHOD.

  METHOD denied_kernel_does_not_read.
    DATA(lo_source) = NEW ltcl_system_source( ).
    DATA(lo_query) = NEW zcl_sec_kernel_query(
      io_source = lo_source
      io_auth   = NEW ltcl_deny_system( ) ).

    TRY.
        lo_query->read_rows( ).
        cl_abap_unit_assert=>fail( 'Authorization failure must raise' ).
      CATCH zcx_sec_settings.
        cl_abap_unit_assert=>assert_false( lo_source->kernel_called ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
