CLASS ltcl_query_util DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS empty_range_matches FOR TESTING.
    METHODS equals_and_pattern FOR TESTING.
    METHODS between_and_exclude FOR TESTING.
    METHODS integer_order_and_blank FOR TESTING.
    METHODS page_window FOR TESTING.
    METHODS closed_period_needs_both_ends FOR TESTING.
    METHODS date_and_timestamp_selection FOR TESTING.
ENDCLASS.

CLASS ltcl_query_util IMPLEMENTATION.
  METHOD empty_range_matches.
    DATA(lt_range) = VALUE zcl_sec_query_util=>tt_range( ).
    cl_abap_unit_assert=>assert_true( zcl_sec_query_util=>matches( iv_value = 'login/min_password_lng' it_range = lt_range ) ).
  ENDMETHOD.

  METHOD equals_and_pattern.
    DATA(lt_eq) = VALUE zcl_sec_query_util=>tt_range( ( sign = 'I' option = 'EQ' low = 'Login/Min_Password_Lng' ) ).
    cl_abap_unit_assert=>assert_true( zcl_sec_query_util=>matches( iv_value = 'login/min_password_lng' it_range = lt_eq ) ).

    DATA(lt_cp) = VALUE zcl_sec_query_util=>tt_range( ( sign = 'I' option = 'CP' low = 'LOGIN/*' ) ).
    cl_abap_unit_assert=>assert_true( zcl_sec_query_util=>matches( iv_value = 'login/fails_to_user_lock' it_range = lt_cp ) ).
    cl_abap_unit_assert=>assert_false( zcl_sec_query_util=>matches( iv_value = 'auth/rfc_authority_check' it_range = lt_cp ) ).
  ENDMETHOD.

  METHOD between_and_exclude.
    DATA(lt_bt) = VALUE zcl_sec_query_util=>tt_range( ( sign = 'I' option = 'BT' low = '20260101' high = '20260131' ) ).
    cl_abap_unit_assert=>assert_true( zcl_sec_query_util=>matches( iv_value = '20260115' it_range = lt_bt ) ).
    cl_abap_unit_assert=>assert_false( zcl_sec_query_util=>matches( iv_value = '20260201' it_range = lt_bt ) ).

    DATA(lt_ex) = VALUE zcl_sec_query_util=>tt_range( ( sign = 'E' option = 'EQ' low = 'P' ) ).
    cl_abap_unit_assert=>assert_false( zcl_sec_query_util=>matches( iv_value = 'P' it_range = lt_ex ) ).
    cl_abap_unit_assert=>assert_true( zcl_sec_query_util=>matches( iv_value = 'T' it_range = lt_ex ) ).
  ENDMETHOD.

  METHOD integer_order_and_blank.
    DATA(lt_gt) = VALUE zcl_sec_query_util=>tt_range( ( sign = 'I' option = 'GT' low = '2' ) ).
    cl_abap_unit_assert=>assert_true( zcl_sec_query_util=>matches( iv_value = '10' it_range = lt_gt ) ).
    cl_abap_unit_assert=>assert_false( zcl_sec_query_util=>matches( iv_value = '2' it_range = lt_gt ) ).

    DATA(lt_blank) = VALUE zcl_sec_query_util=>tt_range( ( sign = 'I' option = 'EQ' low = '' ) ).
    cl_abap_unit_assert=>assert_true( zcl_sec_query_util=>matches( iv_value = ' ' it_range = lt_blank ) ).
  ENDMETHOD.

  METHOD page_window.
    DATA lv_from TYPE i.
    DATA lv_to TYPE i.

    zcl_sec_query_util=>page( EXPORTING iv_lines = 10 iv_skip = 2 iv_top = 3 IMPORTING ev_from = lv_from ev_to = lv_to ).
    cl_abap_unit_assert=>assert_equals( act = lv_from exp = 3 ).
    cl_abap_unit_assert=>assert_equals( act = lv_to exp = 5 ).

    zcl_sec_query_util=>page( EXPORTING iv_lines = 10 iv_skip = 0 iv_top = 0 IMPORTING ev_from = lv_from ev_to = lv_to ).
    cl_abap_unit_assert=>assert_equals( act = lv_to exp = 0 ).

    zcl_sec_query_util=>page( EXPORTING iv_lines = 4 iv_skip = 0 iv_top = -1 IMPORTING ev_from = lv_from ev_to = lv_to ).
    cl_abap_unit_assert=>assert_equals( act = lv_from exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lv_to exp = 4 ).
  ENDMETHOD.

  METHOD closed_period_needs_both_ends.
    DATA(lt_eq) = VALUE zcl_sec_query_util=>tt_range( ( sign = 'I' option = 'EQ' low = '2026-01-15' ) ).
    cl_abap_unit_assert=>assert_true( zcl_sec_query_util=>closed_period( lt_eq ) ).

    DATA(lt_bt) = VALUE zcl_sec_query_util=>tt_range( ( sign = 'I' option = 'BT' low = '20260101' high = '20260131' ) ).
    cl_abap_unit_assert=>assert_true( zcl_sec_query_util=>closed_period( lt_bt ) ).

    DATA(lt_both) = VALUE zcl_sec_query_util=>tt_range(
      ( sign = 'I' option = 'GE' low = '2026-01-01' )
      ( sign = 'I' option = 'LE' low = '2026-01-31' ) ).
    cl_abap_unit_assert=>assert_true( zcl_sec_query_util=>closed_period( lt_both ) ).

    DATA(lt_open) = VALUE zcl_sec_query_util=>tt_range( ( sign = 'I' option = 'GE' low = '2026-01-01' ) ).
    cl_abap_unit_assert=>assert_false( zcl_sec_query_util=>closed_period( lt_open ) ).

    DATA(lt_empty) = VALUE zcl_sec_query_util=>tt_range( ).
    cl_abap_unit_assert=>assert_false( zcl_sec_query_util=>closed_period( lt_empty ) ).
  ENDMETHOD.

  METHOD date_and_timestamp_selection.
    DATA(lt_eq) = VALUE zcl_sec_query_util=>tt_range( ( sign = 'I' option = 'EQ' low = '2026-01-15' ) ).
    DATA(lt_date) = zcl_sec_query_util=>date_selection( it_range = lt_eq iv_name = 'CHANGEDON' ).
    cl_abap_unit_assert=>assert_equals( act = lt_date[ 1 ]-low exp = '20260115' ).

    DATA(lt_stamp) = zcl_sec_query_util=>timestamp_selection( it_range = lt_eq iv_name = 'IMPORTON' ).
    cl_abap_unit_assert=>assert_equals( act = lt_stamp[ 1 ]-option exp = 'BT' ).
    cl_abap_unit_assert=>assert_equals( act = lt_stamp[ 1 ]-low exp = '20260115000000' ).
    cl_abap_unit_assert=>assert_equals( act = lt_stamp[ 1 ]-high exp = '20260115235959' ).

    DATA(lt_both) = VALUE zcl_sec_query_util=>tt_range(
      ( sign = 'I' option = 'GE' low = '2026-01-01' )
      ( sign = 'I' option = 'LE' low = '2026-01-31' ) ).
    DATA(lt_window) = zcl_sec_query_util=>date_selection( it_range = lt_both iv_name = 'CHANGEDON' ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_window ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lt_window[ 1 ]-option exp = 'BT' ).
    cl_abap_unit_assert=>assert_equals( act = lt_window[ 1 ]-low exp = '20260101' ).
    cl_abap_unit_assert=>assert_equals( act = lt_window[ 1 ]-high exp = '20260131' ).

    DATA(lt_span) = zcl_sec_query_util=>timestamp_selection( it_range = lt_both iv_name = 'IMPORTON' ).
    cl_abap_unit_assert=>assert_equals( act = lt_span[ 1 ]-low exp = '20260101000000' ).
    cl_abap_unit_assert=>assert_equals( act = lt_span[ 1 ]-high exp = '20260131235959' ).

    DATA(lt_open) = VALUE zcl_sec_query_util=>tt_range( ( sign = 'I' option = 'GE' low = '2026-01-01' ) ).
    TRY.
        zcl_sec_query_util=>date_selection( it_range = lt_open iv_name = 'CHANGEDON' ).
        cl_abap_unit_assert=>fail( msg = 'An open period is not a selection' ).
      CATCH zcx_sec_settings INTO DATA(lx_open).
        cl_abap_unit_assert=>assert_equals( act = lx_open->if_t100_message~t100key-msgno exp = '004' ).
    ENDTRY.

    DATA(lt_missing) = VALUE zcl_sec_query_util=>tt_range( ).
    TRY.
        zcl_sec_query_util=>date_selection( it_range = lt_missing iv_name = 'CHANGEDON' ).
        cl_abap_unit_assert=>fail( msg = 'A missing date is not a selection' ).
      CATCH zcx_sec_settings INTO DATA(lx_missing).
        cl_abap_unit_assert=>assert_equals( act = lx_missing->if_t100_message~t100key-msgno exp = '005' ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
