CLASS zcl_sec_tcode_usage_db DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_sec_tcode_usage_source.
ENDCLASS.


CLASS zcl_sec_tcode_usage_db IMPLEMENTATION.
  METHOD zif_sec_tcode_usage_source~read_transaction_usage.
    DATA lv_periodtype TYPE swncperitype.
    DATA lv_component TYPE swnchostname.
    DATA ls_text TYPE if_t100_message=>t100key.
    DATA lt_aggregate TYPE STANDARD TABLE OF swncaggusertcode WITH EMPTY KEY.

    lv_periodtype = iv_periodtype.
    lv_component = 'TOTAL'.

    LOOP AT it_periodstart INTO DATA(lv_period).
      CLEAR lt_aggregate.
      CALL FUNCTION 'SWNC_COLLECTOR_GET_AGGREGATES'
        EXPORTING
          component  = lv_component
          periodtype = lv_periodtype
          periodstrt = lv_period
        TABLES
          usertcode  = lt_aggregate
        EXCEPTIONS
          no_data_found = 1
          OTHERS        = 2.
      IF sy-subrc = 1.
        CONTINUE.
      ELSEIF sy-subrc <> 0.
        " Message 003. The text id is local so this class activates against the current exception.
        ls_text-msgid = |ZSEC_ACCESS|.
        ls_text-msgno = |003|.
        RAISE EXCEPTION TYPE zcx_sec_access
          EXPORTING
            textid = ls_text.
      ENDIF.

      LOOP AT lt_aggregate INTO DATA(ls_aggregate).
        IF zcl_sec_query_util=>matches(
             iv_value = CONV string( ls_aggregate-account )
             it_range = it_userid ) = abap_false.
          CONTINUE.
        ENDIF.
        APPEND VALUE #(
          userid               = ls_aggregate-account
          entryid              = ls_aggregate-entry_id
          tasktype             = ls_aggregate-tasktype
          periodtype           = lv_periodtype
          periodstart          = lv_period
          stepcount            = ls_aggregate-count
          dialogstepcount      = ls_aggregate-dcount
          transactioncallcount = ls_aggregate-luw_count ) TO rt_rows.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
