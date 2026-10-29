CLASS zcl_sec_tcode_usage_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        userid               TYPE swncuname,
        entryid              TYPE swncentryid,
        tasktype             TYPE c LENGTH 2,
        periodtype           TYPE swncperitype,
        periodstart          TYPE swncdatum,
        client               TYPE c LENGTH 3,
        stepcount            TYPE swnccntagg,
        dialogstepcount      TYPE swnccntagg,
        transactioncallcount TYPE swnccntagg,
      END OF ty_row,
      tt_row TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY,
      ty_tasktype TYPE c LENGTH 2.

    METHODS constructor
      IMPORTING
        io_source TYPE REF TO zif_sec_tcode_usage_source OPTIONAL
        io_auth   TYPE REF TO zif_sec_tcode_usage_auth OPTIONAL.

    METHODS read_rows
      IMPORTING
        iv_periodtype   TYPE csequence OPTIONAL
        it_periodstart  TYPE zcl_sec_query_util=>tt_range OPTIONAL
        it_userid       TYPE zcl_sec_query_util=>tt_range OPTIONAL
      RETURNING
        VALUE(rt_rows)  TYPE tt_row
      RAISING
        zcx_sec_access.

  PRIVATE SECTION.
    DATA mo_source TYPE REF TO zif_sec_tcode_usage_source.
    DATA mo_auth TYPE REF TO zif_sec_tcode_usage_auth.

    METHODS period_type
      IMPORTING
        iv_periodtype     TYPE csequence
      RETURNING
        VALUE(rv_type)    TYPE swncperitype
      RAISING
        zcx_sec_access.

    METHODS period_starts
      IMPORTING
        iv_periodtype       TYPE swncperitype
        it_periodstart      TYPE zcl_sec_query_util=>tt_range
      RETURNING
        VALUE(rt_starts)    TYPE zif_sec_tcode_usage_source=>tt_date
      RAISING
        zcx_sec_access.

    METHODS canonical_date
      IMPORTING
        iv_value       TYPE csequence
      RETURNING
        VALUE(rv_date) TYPE swncdatum
      RAISING
        zcx_sec_access.

    METHODS period_of
      IMPORTING
        iv_periodtype  TYPE swncperitype
        iv_date        TYPE dats
      RETURNING
        VALUE(rv_date) TYPE swncdatum
      RAISING
        zcx_sec_access.

    METHODS next_period
      IMPORTING
        iv_periodtype  TYPE swncperitype
        iv_date        TYPE dats
      RETURNING
        VALUE(rv_date) TYPE swncdatum.

    METHODS previous_period
      IMPORTING
        iv_periodtype  TYPE swncperitype
        iv_date        TYPE dats
      RETURNING
        VALUE(rv_date) TYPE swncdatum.

    METHODS raise_period
      RAISING
        zcx_sec_access.

    METHODS task_type_of
      IMPORTING
        iv_raw          TYPE swnctasktyperaw
      RETURNING
        VALUE(rv_type)  TYPE ty_tasktype.

    METHODS filter_kept_rows
      IMPORTING
        io_request TYPE REF TO if_rap_query_request
      CHANGING
        ct_rows    TYPE tt_row
      RAISING
        zcx_sec_access.
ENDCLASS.


CLASS zcl_sec_tcode_usage_query IMPLEMENTATION.
  METHOD constructor.
    mo_source = io_source.
    mo_auth = io_auth.
    IF mo_source IS NOT BOUND.
      mo_source = NEW zcl_sec_tcode_usage_db( ).
    ENDIF.
    IF mo_auth IS NOT BOUND.
      mo_auth = NEW zcl_sec_tcode_usage_auth( ).
    ENDIF.
  ENDMETHOD.

  METHOD raise_period.
    RAISE EXCEPTION TYPE zcx_sec_access
      EXPORTING
        textid      = zcx_sec_access=>filter_not_supported
        filter_name = 'PeriodStart'.
  ENDMETHOD.

  METHOD canonical_date.
    DATA lv_text TYPE c LENGTH 8.
    IF iv_value IS INITIAL.
      RETURN.
    ENDIF.
    TRY.
        lv_text = zcl_sec_usr_chg_guard=>date_filter( iv_value ).
      CATCH zcx_sec_access.
        raise_period( ).
    ENDTRY.
    rv_date = lv_text.
  ENDMETHOD.

  METHOD period_type.
    DATA lv_char TYPE c LENGTH 1.
    DATA(lv_type) = to_upper( condense( CONV string( iv_periodtype ) ) ).
    IF lv_type IS INITIAL.
      rv_type = 'M'.
      RETURN.
    ENDIF.
    IF strlen( lv_type ) <> 1 OR ( lv_type <> 'D' AND lv_type <> 'W' AND lv_type <> 'M' ).
      RAISE EXCEPTION TYPE zcx_sec_access
        EXPORTING
          textid      = zcx_sec_access=>filter_not_supported
          filter_name = 'PeriodType'.
    ENDIF.
    lv_char = CONV #( substring( val = lv_type len = 1 ) ).
    rv_type = lv_char.
  ENDMETHOD.

  METHOD period_of.
    DATA lv_text TYPE c LENGTH 8.
    DATA lv_day TYPE scal-indicator.
    rv_date = iv_date.
    IF iv_periodtype = 'M'.
      lv_text = iv_date.
      lv_text+6(2) = '01'.
      rv_date = lv_text.
      RETURN.
    ENDIF.
    IF iv_periodtype = 'W'.
      CALL FUNCTION 'DATE_COMPUTE_DAY'
        EXPORTING
          date = iv_date
        IMPORTING
          day  = lv_day
        EXCEPTIONS
          OTHERS = 1.
      IF sy-subrc <> 0.
        raise_period( ).
      ENDIF.
      rv_date = iv_date - ( lv_day - 1 ).
    ENDIF.
  ENDMETHOD.

  METHOD next_period.
    DATA lv_text TYPE c LENGTH 8.
    DATA lv_year TYPE n LENGTH 4.
    DATA lv_month TYPE n LENGTH 2.
    IF iv_periodtype = 'D'.
      rv_date = iv_date + 1.
      RETURN.
    ENDIF.
    IF iv_periodtype = 'W'.
      rv_date = iv_date + 7.
      RETURN.
    ENDIF.
    lv_text = iv_date.
    lv_year = lv_text(4).
    lv_month = lv_text+4(2).
    IF lv_month = 12.
      lv_year = lv_year + 1.
      lv_month = 1.
    ELSE.
      lv_month = lv_month + 1.
    ENDIF.
    lv_text(4) = lv_year.
    lv_text+4(2) = lv_month.
    lv_text+6(2) = '01'.
    rv_date = lv_text.
  ENDMETHOD.

  METHOD previous_period.
    DATA lv_text TYPE c LENGTH 8.
    DATA lv_year TYPE n LENGTH 4.
    DATA lv_month TYPE n LENGTH 2.
    IF iv_periodtype = 'D'.
      rv_date = iv_date - 1.
      RETURN.
    ENDIF.
    IF iv_periodtype = 'W'.
      rv_date = iv_date - 7.
      RETURN.
    ENDIF.
    lv_text = iv_date.
    lv_year = lv_text(4).
    lv_month = lv_text+4(2).
    IF lv_month = 1.
      lv_year = lv_year - 1.
      lv_month = 12.
    ELSE.
      lv_month = lv_month - 1.
    ENDIF.
    lv_text(4) = lv_year.
    lv_text+4(2) = lv_month.
    lv_text+6(2) = '01'.
    rv_date = lv_text.
  ENDMETHOD.

  METHOD period_starts.
    DATA lv_low TYPE dats.
    DATA lv_high TYPE dats.
    DATA lv_low_set TYPE abap_bool.
    DATA lv_high_set TYPE abap_bool.
    DATA lv_bound TYPE dats.
    DATA lv_max TYPE i.

    IF it_periodstart IS INITIAL.
      raise_period( ).
    ENDIF.

    CASE iv_periodtype.
      WHEN 'D'.
        lv_max = 31.
      WHEN 'W'.
        lv_max = 16.
      WHEN OTHERS.
        lv_max = 24.
    ENDCASE.

    LOOP AT it_periodstart INTO DATA(ls_range).
      IF to_upper( ls_range-sign ) <> 'I'.
        raise_period( ).
      ENDIF.
      CASE to_upper( ls_range-option ).
        WHEN 'EQ'.
          lv_bound = period_of( iv_periodtype = iv_periodtype iv_date = canonical_date( ls_range-low ) ).
          IF lv_low_set = abap_false OR lv_bound > lv_low.
            lv_low = lv_bound.
          ENDIF.
          IF lv_high_set = abap_false OR lv_bound < lv_high.
            lv_high = lv_bound.
          ENDIF.
          lv_low_set = abap_true.
          lv_high_set = abap_true.
        WHEN 'BT'.
          lv_bound = period_of( iv_periodtype = iv_periodtype iv_date = canonical_date( ls_range-low ) ).
          IF lv_low_set = abap_false OR lv_bound > lv_low.
            lv_low = lv_bound.
          ENDIF.
          lv_low_set = abap_true.
          lv_bound = period_of( iv_periodtype = iv_periodtype iv_date = canonical_date( ls_range-high ) ).
          IF lv_high_set = abap_false OR lv_bound < lv_high.
            lv_high = lv_bound.
          ENDIF.
          lv_high_set = abap_true.
        WHEN 'GE'.
          lv_bound = period_of( iv_periodtype = iv_periodtype iv_date = canonical_date( ls_range-low ) ).
          IF lv_low_set = abap_false OR lv_bound > lv_low.
            lv_low = lv_bound.
          ENDIF.
          lv_low_set = abap_true.
        WHEN 'GT'.
          lv_bound = next_period(
            iv_periodtype = iv_periodtype
            iv_date = period_of( iv_periodtype = iv_periodtype iv_date = canonical_date( ls_range-low ) ) ).
          IF lv_low_set = abap_false OR lv_bound > lv_low.
            lv_low = lv_bound.
          ENDIF.
          lv_low_set = abap_true.
        WHEN 'LE'.
          lv_bound = period_of( iv_periodtype = iv_periodtype iv_date = canonical_date( ls_range-low ) ).
          IF lv_high_set = abap_false OR lv_bound < lv_high.
            lv_high = lv_bound.
          ENDIF.
          lv_high_set = abap_true.
        WHEN 'LT'.
          lv_bound = previous_period(
            iv_periodtype = iv_periodtype
            iv_date = period_of( iv_periodtype = iv_periodtype iv_date = canonical_date( ls_range-low ) ) ).
          IF lv_high_set = abap_false OR lv_bound < lv_high.
            lv_high = lv_bound.
          ENDIF.
          lv_high_set = abap_true.
        WHEN OTHERS.
          raise_period( ).
      ENDCASE.
    ENDLOOP.

    IF lv_low_set = abap_false OR lv_high_set = abap_false OR lv_low > lv_high.
      raise_period( ).
    ENDIF.

    DATA(lv_cursor) = lv_low.
    WHILE lv_cursor <= lv_high.
      APPEND lv_cursor TO rt_starts.
      IF lines( rt_starts ) > lv_max.
        raise_period( ).
      ENDIF.
      lv_cursor = next_period( iv_periodtype = iv_periodtype iv_date = lv_cursor ).
    ENDWHILE.
  ENDMETHOD.

  METHOD task_type_of.
    DATA lv_raw TYPE x LENGTH 1.
    lv_raw = iv_raw.
    rv_type = lv_raw.
  ENDMETHOD.

  METHOD read_rows.
    DATA lt_userid TYPE zcl_sec_query_util=>tt_range.
    mo_auth->check_workload_display( ).
    DATA(lv_type) = period_type( iv_periodtype ).
    DATA(lt_starts) = period_starts( iv_periodtype = lv_type it_periodstart = it_periodstart ).

    LOOP AT it_userid INTO DATA(ls_user).
      APPEND VALUE #(
        sign   = ls_user-sign
        option = ls_user-option
        low    = to_upper( ls_user-low )
        high   = to_upper( ls_user-high ) ) TO lt_userid.
    ENDLOOP.

    DATA(lt_raw) = mo_source->read_transaction_usage(
      iv_periodtype  = lv_type
      it_periodstart = lt_starts
      it_userid      = lt_userid ).

    LOOP AT lt_raw INTO DATA(ls_raw).
      APPEND VALUE ty_row(
        userid               = ls_raw-userid
        entryid              = ls_raw-entryid
        tasktype             = task_type_of( ls_raw-tasktype )
        periodtype           = ls_raw-periodtype
        periodstart          = ls_raw-periodstart
        client               = sy-mandt
        stepcount            = ls_raw-stepcount
        dialogstepcount      = ls_raw-dialogstepcount
        transactioncallcount = ls_raw-transactioncallcount ) TO rt_rows.
    ENDLOOP.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    DATA lt_type TYPE zcl_sec_query_util=>tt_range.
    DATA lv_periodtype TYPE string.
    lt_type = zcl_sec_query_util=>ranges_for( io_request = io_request iv_name = 'PERIODTYPE' ).
    IF lines( lt_type ) > 1 OR ( lines( lt_type ) = 1 AND to_upper( lt_type[ 1 ]-option ) <> 'EQ' ).
      RAISE EXCEPTION TYPE zcx_sec_access
        EXPORTING
          textid      = zcx_sec_access=>filter_not_supported
          filter_name = 'PeriodType'.
    ENDIF.
    IF lines( lt_type ) = 1.
      lv_periodtype = lt_type[ 1 ]-low.
    ENDIF.

    DATA(lt_rows) = read_rows(
      iv_periodtype  = lv_periodtype
      it_periodstart = zcl_sec_query_util=>ranges_for( io_request = io_request iv_name = 'PERIODSTART' )
      it_userid      = zcl_sec_query_util=>ranges_for( io_request = io_request iv_name = 'USERID' ) ).

    filter_kept_rows( EXPORTING io_request = io_request CHANGING ct_rows = lt_rows ).

    DATA(lt_sort) = zcl_sec_query_util=>sort_from_request( io_request ).
    zcl_sec_query_util=>sort_by( EXPORTING it_sort = lt_sort CHANGING ct_data = lt_rows ).

    DATA lv_skip TYPE i.
    DATA lv_top TYPE i.
    DATA lv_from TYPE i.
    DATA lv_to TYPE i.
    zcl_sec_query_util=>paging_from_request( EXPORTING io_request = io_request IMPORTING ev_skip = lv_skip ev_top = lv_top ).
    zcl_sec_query_util=>page(
      EXPORTING iv_lines = lines( lt_rows ) iv_skip = lv_skip iv_top = lv_top
      IMPORTING ev_from = lv_from ev_to = lv_to ).

    DATA lt_page TYPE tt_row.
    IF lv_to >= lv_from.
      LOOP AT lt_rows INTO DATA(ls_page) FROM lv_from TO lv_to.
        APPEND ls_page TO lt_page.
      ENDLOOP.
    ENDIF.

    IF io_request->is_data_requested( ) = abap_true.
      io_response->set_data( lt_page ).
    ENDIF.
    IF io_request->is_total_numb_of_rec_requested( ) = abap_true.
      io_response->set_total_number_of_records( lines( lt_rows ) ).
    ENDIF.
  ENDMETHOD.

  METHOD filter_kept_rows.
    " PeriodStart is resolved in the read. A day inside a week is stored as that Monday,
    " so the response date is not the date written in the filter.
    DATA ls_probe TYPE ty_row.
    DATA lt_keep TYPE tt_row.
    DATA lt_range TYPE zcl_sec_query_util=>tt_range.
    DATA lv_name TYPE string.
    DATA lv_keep TYPE abap_bool.
    FIELD-SYMBOLS <field> TYPE any.

    DATA(lt_named) = io_request->get_filter( )->get_as_ranges( ).
    LOOP AT lt_named INTO DATA(ls_named).
      lv_name = to_upper( ls_named-name ).
      IF lv_name = 'PERIODSTART'.
        CONTINUE.
      ENDIF.
      ASSIGN COMPONENT lv_name OF STRUCTURE ls_probe TO <field>.
      IF sy-subrc <> 0.
        RAISE EXCEPTION TYPE zcx_sec_access
          EXPORTING
            textid      = zcx_sec_access=>filter_not_supported
            filter_name = lv_name.
      ENDIF.
    ENDLOOP.

    LOOP AT ct_rows INTO DATA(ls_row).
      lv_keep = abap_true.
      LOOP AT lt_named INTO ls_named.
        lv_name = to_upper( ls_named-name ).
        IF lv_name = 'PERIODSTART'.
          CONTINUE.
        ENDIF.
        ASSIGN COMPONENT lv_name OF STRUCTURE ls_row TO <field>.
        CLEAR lt_range.
        LOOP AT ls_named-range INTO DATA(ls_option).
          APPEND VALUE #(
            sign   = ls_option-sign
            option = ls_option-option
            low    = |{ ls_option-low }|
            high   = |{ ls_option-high }| ) TO lt_range.
        ENDLOOP.
        IF zcl_sec_query_util=>matches( iv_value = |{ <field> }| it_range = lt_range ) = abap_false.
          lv_keep = abap_false.
          EXIT.
        ENDIF.
      ENDLOOP.
      IF lv_keep = abap_true.
        APPEND ls_row TO lt_keep.
      ENDIF.
    ENDLOOP.
    ct_rows = lt_keep.
  ENDMETHOD.
ENDCLASS.
