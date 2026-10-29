CLASS ltcl_source DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_sec_tcode_usage_source.
    DATA called TYPE abap_bool.
    DATA periodtype TYPE string.
    DATA starts TYPE zif_sec_tcode_usage_source=>tt_date.
    DATA userid_low TYPE string.
ENDCLASS.


CLASS ltcl_source IMPLEMENTATION.
  METHOD zif_sec_tcode_usage_source~read_transaction_usage.
    called = abap_true.
    periodtype = iv_periodtype.
    starts = it_periodstart.
    IF lines( it_userid ) > 0.
      userid_low = it_userid[ 1 ]-low.
    ENDIF.
    APPEND VALUE #(
      userid               = |JSMITH|
      entryid              = |FB03|
      tasktype             = CONV #( '01' )
      periodtype           = CONV #( iv_periodtype )
      periodstart          = it_periodstart[ 1 ]
      stepcount            = CONV #( 15 )
      dialogstepcount      = CONV #( 12 )
      transactioncallcount = CONV #( 4 ) ) TO rt_rows.
  ENDMETHOD.
ENDCLASS.


CLASS ltcl_deny DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_sec_tcode_usage_auth.
ENDCLASS.


CLASS ltcl_deny IMPLEMENTATION.
  METHOD zif_sec_tcode_usage_auth~check_workload_display.
    RAISE EXCEPTION TYPE zcx_sec_access
      EXPORTING
        textid = zcx_sec_access=>workload_not_authorized.
  ENDMETHOD.
ENDCLASS.


CLASS ltcl_allow DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_sec_tcode_usage_auth.
ENDCLASS.


CLASS ltcl_allow IMPLEMENTATION.
  METHOD zif_sec_tcode_usage_auth~check_workload_display.
    RETURN.
  ENDMETHOD.
ENDCLASS.


CLASS ltcl_query_auth DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS denied_auth_does_not_read FOR TESTING.
    METHODS month_of_a_day_and_user_filter FOR TESTING.
    METHODS three_days_are_passed FOR TESTING.
    METHODS week_starts_on_monday FOR TESTING.
    METHODS missing_period_does_not_read FOR TESTING.
    METHODS open_period_does_not_read FOR TESTING.
    METHODS too_many_days_does_not_read FOR TESTING.
    METHODS bad_period_type_does_not_read FOR TESTING.
ENDCLASS.


CLASS ltcl_query_auth IMPLEMENTATION.
  METHOD denied_auth_does_not_read.
    DATA(lo_source) = NEW ltcl_source( ).
    DATA(lo_query) = NEW zcl_sec_tcode_usage_query(
      io_source = lo_source
      io_auth   = NEW ltcl_deny( ) ).

    TRY.
        lo_query->read_rows( ).
        cl_abap_unit_assert=>fail( 'Authorization failure must raise' ).
      CATCH zcx_sec_access.
        cl_abap_unit_assert=>assert_false( lo_source->called ).
    ENDTRY.
  ENDMETHOD.

  METHOD month_of_a_day_and_user_filter.
    DATA(lo_source) = NEW ltcl_source( ).
    DATA(lo_query) = NEW zcl_sec_tcode_usage_query(
      io_source = lo_source
      io_auth   = NEW ltcl_allow( ) ).

    DATA(lt_rows) = lo_query->read_rows(
      iv_periodtype  = 'm'
      it_periodstart = VALUE #( ( sign = 'I' option = 'EQ' low = '2026-10-15' ) )
      it_userid      = VALUE #( ( sign = 'I' option = 'EQ' low = 'jsmith' ) ) ).

    cl_abap_unit_assert=>assert_true( lo_source->called ).
    cl_abap_unit_assert=>assert_equals( act = lo_source->periodtype exp = 'M' ).
    cl_abap_unit_assert=>assert_equals( act = lines( lo_source->starts ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lo_source->starts[ 1 ] exp = '20261001' ).
    cl_abap_unit_assert=>assert_equals( act = lo_source->userid_low exp = 'JSMITH' ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_rows ) exp = 1 ).

    DATA(ls_row) = lt_rows[ 1 ].
    cl_abap_unit_assert=>assert_equals( act = condense( ls_row-entryid ) exp = 'FB03' ).
    cl_abap_unit_assert=>assert_equals( act = ls_row-tasktype exp = '01' ).
    cl_abap_unit_assert=>assert_equals( act = ls_row-client exp = sy-mandt ).
    cl_abap_unit_assert=>assert_equals( act = ls_row-stepcount exp = 15 ).
    cl_abap_unit_assert=>assert_equals( act = ls_row-dialogstepcount exp = 12 ).
    cl_abap_unit_assert=>assert_equals( act = ls_row-transactioncallcount exp = 4 ).
  ENDMETHOD.

  METHOD three_days_are_passed.
    DATA(lo_source) = NEW ltcl_source( ).
    DATA(lo_query) = NEW zcl_sec_tcode_usage_query(
      io_source = lo_source
      io_auth   = NEW ltcl_allow( ) ).

    lo_query->read_rows(
      iv_periodtype  = 'D'
      it_periodstart = VALUE #(
        ( sign = 'I' option = 'GE' low = '20261001' )
        ( sign = 'I' option = 'LE' low = '20261003' ) ) ).

    cl_abap_unit_assert=>assert_equals( act = lines( lo_source->starts ) exp = 3 ).
    cl_abap_unit_assert=>assert_equals( act = lo_source->starts[ 1 ] exp = '20261001' ).
    cl_abap_unit_assert=>assert_equals( act = lo_source->starts[ 3 ] exp = '20261003' ).
  ENDMETHOD.

  METHOD week_starts_on_monday.
    DATA(lo_source) = NEW ltcl_source( ).
    DATA(lo_query) = NEW zcl_sec_tcode_usage_query(
      io_source = lo_source
      io_auth   = NEW ltcl_allow( ) ).

    lo_query->read_rows(
      iv_periodtype  = 'W'
      it_periodstart = VALUE #( ( sign = 'I' option = 'EQ' low = '20261015' ) ) ).

    cl_abap_unit_assert=>assert_equals( act = lines( lo_source->starts ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lo_source->starts[ 1 ] exp = '20261012' ).
  ENDMETHOD.

  METHOD missing_period_does_not_read.
    DATA(lo_source) = NEW ltcl_source( ).
    DATA(lo_query) = NEW zcl_sec_tcode_usage_query(
      io_source = lo_source
      io_auth   = NEW ltcl_allow( ) ).

    TRY.
        lo_query->read_rows( iv_periodtype = 'M' ).
        cl_abap_unit_assert=>fail( 'A missing period must raise' ).
      CATCH zcx_sec_access.
        cl_abap_unit_assert=>assert_false( lo_source->called ).
    ENDTRY.
  ENDMETHOD.

  METHOD open_period_does_not_read.
    DATA(lo_source) = NEW ltcl_source( ).
    DATA(lo_query) = NEW zcl_sec_tcode_usage_query(
      io_source = lo_source
      io_auth   = NEW ltcl_allow( ) ).

    TRY.
        lo_query->read_rows(
          iv_periodtype  = 'M'
          it_periodstart = VALUE #( ( sign = 'I' option = 'GE' low = '20260101' ) ) ).
        cl_abap_unit_assert=>fail( 'A period without an end must raise' ).
      CATCH zcx_sec_access.
        cl_abap_unit_assert=>assert_false( lo_source->called ).
    ENDTRY.
  ENDMETHOD.

  METHOD too_many_days_does_not_read.
    DATA(lo_source) = NEW ltcl_source( ).
    DATA(lo_query) = NEW zcl_sec_tcode_usage_query(
      io_source = lo_source
      io_auth   = NEW ltcl_allow( ) ).

    TRY.
        lo_query->read_rows(
          iv_periodtype  = 'D'
          it_periodstart = VALUE #(
            ( sign = 'I' option = 'GE' low = '20260101' )
            ( sign = 'I' option = 'LE' low = '20260301' ) ) ).
        cl_abap_unit_assert=>fail( 'More than 31 days must raise' ).
      CATCH zcx_sec_access.
        cl_abap_unit_assert=>assert_false( lo_source->called ).
    ENDTRY.
  ENDMETHOD.

  METHOD bad_period_type_does_not_read.
    DATA(lo_source) = NEW ltcl_source( ).
    DATA(lo_query) = NEW zcl_sec_tcode_usage_query(
      io_source = lo_source
      io_auth   = NEW ltcl_allow( ) ).

    TRY.
        lo_query->read_rows(
          iv_periodtype  = 'Y'
          it_periodstart = VALUE #( ( sign = 'I' option = 'EQ' low = '20261001' ) ) ).
        cl_abap_unit_assert=>fail( 'A period type other than D, W, or M must raise' ).
      CATCH zcx_sec_access.
        cl_abap_unit_assert=>assert_false( lo_source->called ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
