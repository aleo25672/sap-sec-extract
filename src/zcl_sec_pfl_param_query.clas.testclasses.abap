CLASS ltcl_deny_auth DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_sec_auth.
ENDCLASS.

CLASS ltcl_deny_auth IMPLEMENTATION.
  METHOD zif_sec_auth~check_profile_display.
    RAISE EXCEPTION TYPE zcx_sec_settings
      EXPORTING
        textid = zcx_sec_settings=>not_authorized.
  ENDMETHOD.
  METHOD zif_sec_auth~check_policy_display.
  ENDMETHOD.
  METHOD zif_sec_auth~check_client_display.
  ENDMETHOD.
  METHOD zif_sec_auth~check_system_change_display.
  ENDMETHOD.
  METHOD zif_sec_auth~can_count_users.
    rv_yes = abap_false.
  ENDMETHOD.
ENDCLASS.

CLASS ltcl_source DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_sec_pfl_param_source.
    DATA called TYPE abap_bool.
ENDCLASS.

CLASS ltcl_source IMPLEMENTATION.
  METHOD zif_sec_pfl_param_source~read.
    called = abap_true.
  ENDMETHOD.
ENDCLASS.

CLASS ltcl_query_auth DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS denied_auth_does_not_read FOR TESTING.
ENDCLASS.

CLASS ltcl_query_auth IMPLEMENTATION.
  METHOD denied_auth_does_not_read.
    DATA(lo_source) = NEW ltcl_source( ).
    DATA(lo_query) = NEW zcl_sec_pfl_param_query(
      io_source = lo_source
      io_auth   = NEW ltcl_deny_auth( ) ).

    TRY.
        lo_query->read_rows( ).
        cl_abap_unit_assert=>fail( 'Authorization failure must raise' ).
      CATCH zcx_sec_settings.
        cl_abap_unit_assert=>assert_false( lo_source->called ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
