CLASS zcl_sec_tcode_usage_db DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_sec_tcode_usage_source.

  PRIVATE SECTION.
    TYPES:
      tt_aggregate TYPE STANDARD TABLE OF swncaggusertcode WITH EMPTY KEY,
      BEGIN OF ty_sum,
        tasktype  TYPE swnctasktyperaw,
        account   TYPE swncuname,
        entry_id  TYPE swncentryid,
        count     TYPE swnccntagg,
        dcount    TYPE swnccntagg,
        luw_count TYPE swnccntagg,
      END OF ty_sum,
      tt_sum TYPE STANDARD TABLE OF ty_sum WITH DEFAULT KEY.

    METHODS read_aggregate
      IMPORTING
        iv_periodtype  TYPE swncperitype
        iv_period      TYPE swncdatum
      EXPORTING
        et_aggregate   TYPE tt_aggregate
        ev_found       TYPE abap_bool
      RAISING
        zcx_sec_access.

    METHODS week_from_days
      IMPORTING
        iv_monday      TYPE swncdatum
      RETURNING
        VALUE(rt_sum)  TYPE tt_sum
      RAISING
        zcx_sec_access.

    METHODS append_usage
      IMPORTING
        it_aggregate   TYPE tt_aggregate
        iv_periodtype  TYPE swncperitype
        iv_period      TYPE swncdatum
        it_userid      TYPE zcl_sec_query_util=>tt_range
      CHANGING
        ct_rows        TYPE zif_sec_tcode_usage_source=>tt_usage.
ENDCLASS.


CLASS zcl_sec_tcode_usage_db IMPLEMENTATION.
  METHOD zif_sec_tcode_usage_source~read_transaction_usage.
    DATA lv_periodtype TYPE swncperitype.
    DATA lt_aggregate TYPE tt_aggregate.
    DATA lt_sum TYPE tt_sum.
    DATA ls_aggregate TYPE swncaggusertcode.
    DATA lv_found TYPE abap_bool.

    lv_periodtype = iv_periodtype.

    LOOP AT it_periodstart INTO DATA(lv_period).
      read_aggregate(
        EXPORTING
          iv_periodtype = lv_periodtype
          iv_period     = lv_period
        IMPORTING
          et_aggregate  = lt_aggregate
          ev_found      = lv_found ).
      IF lv_found = abap_false.
        CLEAR lt_aggregate.
      ENDIF.
      IF lv_found = abap_false AND lv_periodtype = 'W'.
        " The collector often stores the month and not the week. Add the seven days.
        lt_sum = week_from_days( lv_period ).
        LOOP AT lt_sum INTO DATA(ls_sum).
          CLEAR ls_aggregate.
          ls_aggregate-tasktype = ls_sum-tasktype.
          ls_aggregate-account = ls_sum-account.
          ls_aggregate-entry_id = ls_sum-entry_id.
          ls_aggregate-count = ls_sum-count.
          ls_aggregate-dcount = ls_sum-dcount.
          ls_aggregate-luw_count = ls_sum-luw_count.
          APPEND ls_aggregate TO lt_aggregate.
        ENDLOOP.
      ENDIF.
      append_usage(
        EXPORTING
          it_aggregate  = lt_aggregate
          iv_periodtype = lv_periodtype
          iv_period     = lv_period
          it_userid     = it_userid
        CHANGING
          ct_rows       = rt_rows ).
    ENDLOOP.
  ENDMETHOD.

  METHOD read_aggregate.
    DATA lv_component TYPE swnchostname.
    DATA ls_text LIKE if_t100_message=>t100key.
    CLEAR et_aggregate.
    ev_found = abap_false.
    lv_component = 'TOTAL'.
    CALL FUNCTION 'SWNC_COLLECTOR_GET_AGGREGATES'
      EXPORTING
        component  = lv_component
        periodtype = iv_periodtype
        periodstrt = iv_period
      TABLES
        usertcode  = et_aggregate
      EXCEPTIONS
        no_data_found = 1
        OTHERS        = 2.
    IF sy-subrc = 0.
      ev_found = abap_true.
      RETURN.
    ENDIF.
    IF sy-subrc = 1.
      RETURN.
    ENDIF.
    " Message 003. The text id is local so this class activates against the current exception.
    ls_text-msgid = |ZSEC_ACCESS|.
    ls_text-msgno = |003|.
    RAISE EXCEPTION TYPE zcx_sec_access
      EXPORTING
        textid = ls_text.
  ENDMETHOD.

  METHOD week_from_days.
    DATA lv_day TYPE swncdatum.
    DATA lv_offset TYPE i.
    DATA lt_day TYPE tt_aggregate.
    DATA ls_sum TYPE ty_sum.
    DATA lv_found TYPE abap_bool.
    DATA lv_daytype TYPE swncperitype.

    lv_daytype = 'D'.
    DO 7 TIMES.
      lv_offset = sy-index - 1.
      lv_day = iv_monday + lv_offset.
      read_aggregate(
        EXPORTING
          iv_periodtype = lv_daytype
          iv_period     = lv_day
        IMPORTING
          et_aggregate  = lt_day
          ev_found      = lv_found ).
      IF lv_found = abap_false.
        CONTINUE.
      ENDIF.
      LOOP AT lt_day INTO DATA(ls_day).
        CLEAR ls_sum.
        ls_sum-tasktype = ls_day-tasktype.
        ls_sum-account = ls_day-account.
        ls_sum-entry_id = ls_day-entry_id.
        ls_sum-count = ls_day-count.
        ls_sum-dcount = ls_day-dcount.
        ls_sum-luw_count = ls_day-luw_count.
        COLLECT ls_sum INTO rt_sum.
      ENDLOOP.
    ENDDO.
  ENDMETHOD.

  METHOD append_usage.
    LOOP AT it_aggregate INTO DATA(ls_aggregate).
      IF zcl_sec_query_util=>matches(
           iv_value = CONV string( ls_aggregate-account )
           it_range = it_userid ) = abap_false.
        CONTINUE.
      ENDIF.
      APPEND VALUE #(
        userid               = ls_aggregate-account
        entryid              = ls_aggregate-entry_id
        tasktype             = ls_aggregate-tasktype
        periodtype           = iv_periodtype
        periodstart          = iv_period
        stepcount            = ls_aggregate-count
        dialogstepcount      = ls_aggregate-dcount
        transactioncallcount = ls_aggregate-luw_count ) TO ct_rows.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
