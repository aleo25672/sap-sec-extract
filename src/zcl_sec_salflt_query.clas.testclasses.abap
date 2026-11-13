CLASS ltcl_deny_salflt DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_sec_access_auth.
ENDCLASS.

CLASS ltcl_deny_salflt IMPLEMENTATION.
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

CLASS ltcl_salflt DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS system_events_aue_to_auj FOR TESTING.
    METHODS area_f_is_the_fourth_bit FOR TESTING.
    METHODS denied_audit_does_not_read FOR TESTING.
ENDCLASS.

CLASS ltcl_salflt IMPLEMENTATION.
  METHOD system_events_aue_to_auj.
    DATA lv_vector TYPE x LENGTH 20 VALUE '0000000000000000000000000000808080808080'.
    DATA(lt_ids) = zcl_sec_salflt_query=>message_ids( CONV xstring( lv_vector ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_ids ) exp = 6 ).
    cl_abap_unit_assert=>assert_equals( act = lt_ids[ 1 ] exp = 'AUE' ).
    cl_abap_unit_assert=>assert_equals( act = lt_ids[ 2 ] exp = 'AUF' ).
    cl_abap_unit_assert=>assert_equals( act = lt_ids[ 3 ] exp = 'AUG' ).
    cl_abap_unit_assert=>assert_equals( act = lt_ids[ 4 ] exp = 'AUH' ).
    cl_abap_unit_assert=>assert_equals( act = lt_ids[ 5 ] exp = 'AUI' ).
    cl_abap_unit_assert=>assert_equals( act = lt_ids[ 6 ] exp = 'AUJ' ).
  ENDMETHOD.

  METHOD area_f_is_the_fourth_bit.
    DATA lv_vector TYPE x LENGTH 3 VALUE '040004'.
    DATA(lt_ids) = zcl_sec_salflt_query=>message_ids( CONV xstring( lv_vector ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_ids ) exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = lt_ids[ 1 ] exp = 'FU0' ).
    cl_abap_unit_assert=>assert_equals( act = lt_ids[ 2 ] exp = 'FU2' ).
  ENDMETHOD.

  METHOD denied_audit_does_not_read.
    DATA lv_raised TYPE abap_bool.
    TRY.
        NEW zcl_sec_salflt_query( io_auth = NEW ltcl_deny_salflt( ) )->read_rows( ).
      CATCH zcx_sec_access.
        lv_raised = abap_true.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( lv_raised ).
  ENDMETHOD.
ENDCLASS.
