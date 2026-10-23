CLASS ltcl_query_util DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS empty_range_matches FOR TESTING.
    METHODS equals_and_pattern FOR TESTING.
    METHODS between_and_exclude FOR TESTING.
    METHODS integer_order_and_blank FOR TESTING.
    METHODS page_window FOR TESTING.
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
ENDCLASS.
