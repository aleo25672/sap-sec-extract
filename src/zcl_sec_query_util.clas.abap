CLASS zcl_sec_query_util DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_range,
        sign   TYPE c LENGTH 1,
        option TYPE c LENGTH 2,
        low    TYPE string,
        high   TYPE string,
      END OF ty_range,
      tt_range TYPE STANDARD TABLE OF ty_range WITH EMPTY KEY,
      BEGIN OF ty_sort,
        name       TYPE string,
        descending TYPE abap_bool,
      END OF ty_sort,
      tt_sort TYPE STANDARD TABLE OF ty_sort WITH EMPTY KEY.

    CLASS-METHODS matches
      IMPORTING
        iv_value       TYPE string
        it_range       TYPE tt_range
      RETURNING
        VALUE(rv_yes) TYPE abap_bool.

    CLASS-METHODS page
      IMPORTING
        iv_lines     TYPE i
        iv_skip      TYPE i
        iv_top       TYPE i
      EXPORTING
        ev_from      TYPE i
        ev_to        TYPE i.

    CLASS-METHODS ranges_for
      IMPORTING
        io_request       TYPE REF TO if_rap_query_request
        iv_name          TYPE string
      RETURNING
        VALUE(rt_range)  TYPE tt_range.

    CLASS-METHODS sort_from_request
      IMPORTING
        io_request      TYPE REF TO if_rap_query_request
      RETURNING
        VALUE(rt_sort)  TYPE tt_sort.

    CLASS-METHODS sort_by
      IMPORTING
        it_sort TYPE tt_sort
      CHANGING
        ct_data TYPE ANY TABLE.

    CLASS-METHODS paging_from_request
      IMPORTING
        io_request TYPE REF TO if_rap_query_request
      EXPORTING
        ev_skip    TYPE i
        ev_top     TYPE i.

    CLASS-METHODS filter_rows
      IMPORTING
        io_request TYPE REF TO if_rap_query_request
      CHANGING
        ct_rows    TYPE STANDARD TABLE
      RAISING
        cx_rap_query_provider.

    CLASS-METHODS require_filter
      IMPORTING
        io_request TYPE REF TO if_rap_query_request
        iv_name    TYPE string
      RAISING
        zcx_sec_settings.

    CLASS-METHODS apply
      IMPORTING
        io_request  TYPE REF TO if_rap_query_request
        io_response TYPE REF TO if_rap_query_response
      CHANGING
        ct_rows     TYPE STANDARD TABLE
      RAISING
        cx_rap_query_provider.

    CLASS-METHODS apply_access
      IMPORTING
        io_request  TYPE REF TO if_rap_query_request
        io_response TYPE REF TO if_rap_query_response
      CHANGING
        ct_rows     TYPE STANDARD TABLE
      RAISING
        zcx_sec_access.

    CLASS-METHODS closed_period
      IMPORTING
        it_range      TYPE tt_range
      RETURNING
        VALUE(rv_yes) TYPE abap_bool.

    CLASS-METHODS canonical_date
      IMPORTING
        iv_value       TYPE csequence
        iv_name        TYPE csequence
      RETURNING
        VALUE(rv_date) TYPE string
      RAISING
        zcx_sec_settings.

    CLASS-METHODS date_selection
      IMPORTING
        it_range        TYPE tt_range
        iv_name         TYPE csequence
      RETURNING
        VALUE(rt_range) TYPE tt_range
      RAISING
        zcx_sec_settings.

    CLASS-METHODS timestamp_selection
      IMPORTING
        it_range        TYPE tt_range
        iv_name         TYPE csequence
      RETURNING
        VALUE(rt_range) TYPE tt_range
      RAISING
        zcx_sec_settings.

    CLASS-METHODS access_date_selection
      IMPORTING
        it_range        TYPE tt_range
        iv_name         TYPE csequence
      RETURNING
        VALUE(rt_range) TYPE tt_range
      RAISING
        zcx_sec_access.

    CLASS-METHODS access_timestamp_selection
      IMPORTING
        it_range        TYPE tt_range
        iv_name         TYPE csequence
      RETURNING
        VALUE(rt_range) TYPE tt_range
      RAISING
        zcx_sec_access.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_named_range,
        name  TYPE string,
        range TYPE tt_range,
      END OF ty_named_range,
      tt_named_range TYPE STANDARD TABLE OF ty_named_range WITH EMPTY KEY.

    CLASS-METHODS filters_from
      IMPORTING
        io_request         TYPE REF TO if_rap_query_request
      RETURNING
        VALUE(rt_filters)  TYPE tt_named_range
      RAISING
        cx_rap_query_provider.

    CLASS-METHODS is_integer
      IMPORTING
        iv_value       TYPE string
      RETURNING
        VALUE(rv_yes)  TYPE abap_bool.

    CLASS-METHODS raise_as_access
      IMPORTING
        ix_settings TYPE REF TO zcx_sec_settings
      RAISING
        zcx_sec_access.
ENDCLASS.


CLASS zcl_sec_query_util IMPLEMENTATION.
  METHOD matches.
    IF it_range IS INITIAL.
      rv_yes = abap_true.
      RETURN.
    ENDIF.

    DATA(lv_included) = abap_false.
    DATA(lv_has_include) = abap_false.
    DATA(lv_excluded) = abap_false.
    DATA(lv_value_raw) = condense( iv_value ).
    DATA(lv_value) = to_upper( lv_value_raw ).

    LOOP AT it_range INTO DATA(ls_range).
      DATA(lv_low_raw) = condense( ls_range-low ).
      DATA(lv_high_raw) = condense( ls_range-high ).
      DATA(lv_low) = to_upper( lv_low_raw ).
      DATA(lv_high) = to_upper( lv_high_raw ).
      DATA(lv_option) = to_upper( ls_range-option ).
      DATA(lv_hit) = abap_false.
      DATA(lv_numeric) = abap_false.

      IF ( lv_option = 'GT' OR lv_option = 'GE' OR lv_option = 'LT' OR lv_option = 'LE' OR lv_option = 'BT' )
        AND is_integer( lv_value_raw ) = abap_true
        AND is_integer( lv_low_raw ) = abap_true
        AND ( lv_option <> 'BT' OR is_integer( lv_high_raw ) = abap_true ).
        lv_numeric = abap_true.
      ENDIF.

      IF lv_numeric = abap_true.
        DATA lv_number TYPE p LENGTH 16 DECIMALS 0.
        DATA lv_number_low TYPE p LENGTH 16 DECIMALS 0.
        DATA lv_number_high TYPE p LENGTH 16 DECIMALS 0.
        lv_number = lv_value_raw.
        lv_number_low = lv_low_raw.
        IF lv_option = 'BT'.
          lv_number_high = lv_high_raw.
        ENDIF.
        CASE lv_option.
          WHEN 'GT'.
            lv_hit = xsdbool( lv_number > lv_number_low ).
          WHEN 'GE'.
            lv_hit = xsdbool( lv_number >= lv_number_low ).
          WHEN 'LT'.
            lv_hit = xsdbool( lv_number < lv_number_low ).
          WHEN 'LE'.
            lv_hit = xsdbool( lv_number <= lv_number_low ).
          WHEN 'BT'.
            lv_hit = xsdbool( lv_number >= lv_number_low AND lv_number <= lv_number_high ).
        ENDCASE.
      ELSE.
        CASE lv_option.
          WHEN 'EQ'.
            lv_hit = xsdbool( lv_value = lv_low ).
          WHEN 'NE'.
            lv_hit = xsdbool( lv_value <> lv_low ).
          WHEN 'CP'.
            lv_hit = xsdbool( lv_value CP lv_low ).
          WHEN 'NP'.
            lv_hit = xsdbool( lv_value NP lv_low ).
          WHEN 'BT'.
            lv_hit = xsdbool( lv_value >= lv_low AND lv_value <= lv_high ).
          WHEN 'GE'.
            lv_hit = xsdbool( lv_value >= lv_low ).
          WHEN 'GT'.
            lv_hit = xsdbool( lv_value > lv_low ).
          WHEN 'LE'.
            lv_hit = xsdbool( lv_value <= lv_low ).
          WHEN 'LT'.
            lv_hit = xsdbool( lv_value < lv_low ).
          WHEN OTHERS.
            lv_hit = abap_false.
        ENDCASE.
      ENDIF.

      IF to_upper( ls_range-sign ) = 'E'.
        IF lv_hit = abap_true.
          lv_excluded = abap_true.
        ENDIF.
      ELSE.
        lv_has_include = abap_true.
        IF lv_hit = abap_true.
          lv_included = abap_true.
        ENDIF.
      ENDIF.
    ENDLOOP.

    IF lv_excluded = abap_true.
      rv_yes = abap_false.
    ELSEIF lv_has_include = abap_false.
      rv_yes = abap_true.
    ELSE.
      rv_yes = lv_included.
    ENDIF.
  ENDMETHOD.

  METHOD page.
    IF iv_lines <= 0 OR iv_top = 0.
      ev_from = 1.
      ev_to = 0.
      RETURN.
    ENDIF.

    DATA(lv_skip) = COND i( WHEN iv_skip < 0 THEN 0 ELSE iv_skip ).
    ev_from = lv_skip + 1.
    IF iv_top < 0.
      ev_to = iv_lines.
    ELSE.
      ev_to = nmin( val1 = iv_lines val2 = lv_skip + iv_top ).
    ENDIF.
    IF ev_from > ev_to.
      ev_from = 1.
      ev_to = 0.
    ENDIF.
  ENDMETHOD.

  METHOD ranges_for.
    DATA(lt_named) = io_request->get_filter( )->get_as_ranges( ).
    DATA(lv_name) = to_upper( iv_name ).
    LOOP AT lt_named INTO DATA(ls_named).
      IF to_upper( ls_named-name ) <> lv_name.
        CONTINUE.
      ENDIF.
      LOOP AT ls_named-range INTO DATA(ls_option).
        APPEND VALUE ty_range(
          sign   = ls_option-sign
          option = ls_option-option
          low    = |{ ls_option-low }|
          high   = |{ ls_option-high }| ) TO rt_range.
      ENDLOOP.
      RETURN.
    ENDLOOP.
  ENDMETHOD.

  METHOD sort_from_request.
    DATA(lt_sort) = io_request->get_sort_elements( ).
    LOOP AT lt_sort INTO DATA(ls_sort).
      APPEND VALUE ty_sort(
        name       = to_upper( ls_sort-element_name )
        descending = ls_sort-descending ) TO rt_sort.
    ENDLOOP.
  ENDMETHOD.

  METHOD sort_by.
    DATA lt_reversed TYPE tt_sort.
    LOOP AT it_sort INTO DATA(ls_sort).
      INSERT ls_sort INTO lt_reversed INDEX 1.
    ENDLOOP.

    LOOP AT lt_reversed INTO ls_sort.
      TRY.
          IF ls_sort-descending = abap_true.
            SORT ct_data STABLE BY (ls_sort-name) DESCENDING.
          ELSE.
            SORT ct_data STABLE BY (ls_sort-name) ASCENDING.
          ENDIF.
        CATCH cx_sy_itab_dyn_loop.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.

  METHOD paging_from_request.
    ev_skip = 0.
    ev_top = -1.
    DATA(lo_paging) = io_request->get_paging( ).
    IF lo_paging IS BOUND.
      ev_skip = lo_paging->get_offset( ).
      ev_top = lo_paging->get_page_size( ).
    ENDIF.
  ENDMETHOD.

  METHOD is_integer.
    DATA(lv_value) = condense( iv_value ).
    IF lv_value IS INITIAL.
      rv_yes = abap_false.
      RETURN.
    ENDIF.
    IF lv_value(1) = '-'.
      IF strlen( lv_value ) < 2.
        rv_yes = abap_false.
        RETURN.
      ENDIF.
      lv_value = lv_value+1.
    ENDIF.
    rv_yes = xsdbool( lv_value CO '0123456789' ).
  ENDMETHOD.

  METHOD filters_from.
    DATA(lt_named) = io_request->get_filter( )->get_as_ranges( ).
    LOOP AT lt_named INTO DATA(ls_named).
      DATA(ls_filter) = VALUE ty_named_range( name = to_upper( ls_named-name ) ).
      LOOP AT ls_named-range INTO DATA(ls_option).
        APPEND VALUE ty_range(
          sign   = ls_option-sign
          option = ls_option-option
          low    = |{ ls_option-low }|
          high   = |{ ls_option-high }| ) TO ls_filter-range.
      ENDLOOP.
      APPEND ls_filter TO rt_filters.
    ENDLOOP.
  ENDMETHOD.

  METHOD filter_rows.
    DATA(lt_filters) = filters_from( io_request ).

    FIELD-SYMBOLS:
      <probe>       TYPE any,
      <probe_field> TYPE any,
      <keep>        TYPE STANDARD TABLE,
      <row>         TYPE any,
      <kept>        TYPE any.

    DATA lr_probe TYPE REF TO data.
    CREATE DATA lr_probe LIKE LINE OF ct_rows.
    ASSIGN lr_probe->* TO <probe>.
    LOOP AT lt_filters INTO DATA(ls_filter).
      ASSIGN COMPONENT ls_filter-name OF STRUCTURE <probe> TO <probe_field>.
      IF sy-subrc <> 0 OR <probe_field> IS NOT ASSIGNED.
        RAISE EXCEPTION TYPE zcx_sec_settings
          EXPORTING
            textid      = zcx_sec_settings=>filter_not_supported
            filter_name = ls_filter-name.
      ENDIF.
    ENDLOOP.

    DATA lr_keep TYPE REF TO data.
    CREATE DATA lr_keep LIKE ct_rows.
    ASSIGN lr_keep->* TO <keep>.

    LOOP AT ct_rows ASSIGNING <row>.
      DATA(lv_keep) = abap_true.
      LOOP AT lt_filters INTO ls_filter.
        ASSIGN COMPONENT ls_filter-name OF STRUCTURE <row> TO FIELD-SYMBOL(<value>).
        IF matches( iv_value = |{ <value> }| it_range = ls_filter-range ) = abap_false.
          lv_keep = abap_false.
          EXIT.
        ENDIF.
      ENDLOOP.
      IF lv_keep = abap_true.
        APPEND <row> TO <keep>.
      ENDIF.
    ENDLOOP.

    CLEAR ct_rows.
    LOOP AT <keep> ASSIGNING <kept>.
      APPEND <kept> TO ct_rows.
    ENDLOOP.
  ENDMETHOD.

  METHOD require_filter.
    IF ranges_for( io_request = io_request iv_name = iv_name ) IS INITIAL.
      RAISE EXCEPTION TYPE zcx_sec_settings
        EXPORTING
          textid      = zcx_sec_settings=>filter_required
          filter_name = to_upper( iv_name ).
    ENDIF.
  ENDMETHOD.

  METHOD apply.
    filter_rows( EXPORTING io_request = io_request CHANGING ct_rows = ct_rows ).

    DATA(lt_sort) = sort_from_request( io_request ).
    sort_by( EXPORTING it_sort = lt_sort CHANGING ct_data = ct_rows ).

    DATA lv_skip TYPE i.
    DATA lv_top TYPE i.
    DATA lv_from TYPE i.
    DATA lv_to TYPE i.
    paging_from_request( EXPORTING io_request = io_request IMPORTING ev_skip = lv_skip ev_top = lv_top ).
    page(
      EXPORTING iv_lines = lines( ct_rows ) iv_skip = lv_skip iv_top = lv_top
      IMPORTING ev_from = lv_from ev_to = lv_to ).

    DATA lr_page TYPE REF TO data.
    FIELD-SYMBOLS <page> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <row> TYPE any.
    CREATE DATA lr_page LIKE ct_rows.
    ASSIGN lr_page->* TO <page>.
    IF lv_to >= lv_from.
      LOOP AT ct_rows ASSIGNING <row> FROM lv_from TO lv_to.
        APPEND <row> TO <page>.
      ENDLOOP.
    ENDIF.

    IF io_request->is_data_requested( ) = abap_true.
      io_response->set_data( <page> ).
    ENDIF.
    IF io_request->is_total_numb_of_rec_requested( ) = abap_true.
      io_response->set_total_number_of_records( lines( ct_rows ) ).
    ENDIF.
  ENDMETHOD.

  METHOD apply_access.
    TRY.
        apply( EXPORTING io_request = io_request io_response = io_response CHANGING ct_rows = ct_rows ).
      CATCH zcx_sec_settings INTO DATA(lx_settings).
        raise_as_access( lx_settings ).
    ENDTRY.
  ENDMETHOD.

  METHOD raise_as_access.
    DATA(ls_key) = ix_settings->if_t100_message~t100key.
    IF ls_key-msgno = '005'.
      RAISE EXCEPTION TYPE zcx_sec_access
        EXPORTING
          textid      = zcx_sec_access=>filter_required
          filter_name = ix_settings->filter_name.
    ENDIF.
    RAISE EXCEPTION TYPE zcx_sec_access
      EXPORTING
        textid      = zcx_sec_access=>filter_not_supported
        filter_name = ix_settings->filter_name.
  ENDMETHOD.

  METHOD closed_period.
    DATA lv_low TYPE abap_bool.
    DATA lv_high TYPE abap_bool.
    LOOP AT it_range INTO DATA(ls_range).
      IF to_upper( ls_range-sign ) = 'E'.
        CONTINUE.
      ENDIF.
      CASE to_upper( ls_range-option ).
        WHEN 'EQ' OR 'BT'.
          lv_low = abap_true.
          lv_high = abap_true.
        WHEN 'GE' OR 'GT'.
          lv_low = abap_true.
        WHEN 'LE' OR 'LT'.
          lv_high = abap_true.
        WHEN OTHERS.
          RETURN.
      ENDCASE.
    ENDLOOP.
    rv_yes = xsdbool( lv_low = abap_true AND lv_high = abap_true ).
  ENDMETHOD.

  METHOD canonical_date.
    DATA(lv_raw) = condense( CONV string( iv_value ) ).
    IF lv_raw IS INITIAL.
      RETURN.
    ENDIF.
    DATA(lv_t) = find( val = lv_raw sub = 'T' ).
    IF lv_t > 0.
      lv_raw = substring( val = lv_raw len = lv_t ).
    ENDIF.
    lv_raw = replace( val = lv_raw sub = '-' with = '' occ = 0 ).
    lv_raw = replace( val = lv_raw sub = '/' with = '' occ = 0 ).
    CONDENSE lv_raw NO-GAPS.
    IF strlen( lv_raw ) <> 8 OR lv_raw CN '0123456789'.
      RAISE EXCEPTION TYPE zcx_sec_settings
        EXPORTING
          textid      = zcx_sec_settings=>filter_not_supported
          filter_name = to_upper( iv_name ).
    ENDIF.
    rv_date = lv_raw.
  ENDMETHOD.

  METHOD date_selection.
    IF it_range IS INITIAL.
      RAISE EXCEPTION TYPE zcx_sec_settings
        EXPORTING
          textid      = zcx_sec_settings=>filter_required
          filter_name = to_upper( iv_name ).
    ENDIF.
    IF closed_period( it_range ) = abap_false.
      RAISE EXCEPTION TYPE zcx_sec_settings
        EXPORTING
          textid      = zcx_sec_settings=>filter_not_supported
          filter_name = to_upper( iv_name ).
    ENDIF.
    DATA lt_include TYPE tt_range.
    DATA lt_exclude TYPE tt_range.
    LOOP AT it_range INTO DATA(ls_range).
      DATA(lv_option) = to_upper( ls_range-option ).
      IF lv_option = 'BT' AND ( ls_range-low IS INITIAL OR ls_range-high IS INITIAL ).
        RAISE EXCEPTION TYPE zcx_sec_settings
          EXPORTING
            textid      = zcx_sec_settings=>filter_not_supported
            filter_name = to_upper( iv_name ).
      ENDIF.
      IF lv_option <> 'BT' AND ls_range-low IS INITIAL AND to_upper( ls_range-sign ) <> 'E'.
        RAISE EXCEPTION TYPE zcx_sec_settings
          EXPORTING
            textid      = zcx_sec_settings=>filter_not_supported
            filter_name = to_upper( iv_name ).
      ENDIF.
      DATA(ls_date) = VALUE ty_range(
        sign   = ls_range-sign
        option = lv_option
        low    = canonical_date( iv_value = ls_range-low iv_name = iv_name )
        high   = canonical_date( iv_value = ls_range-high iv_name = iv_name ) ).
      IF to_upper( ls_range-sign ) = 'E'.
        APPEND ls_date TO lt_exclude.
      ELSE.
        APPEND ls_date TO lt_include.
      ENDIF.
    ENDLOOP.

    " Two include lines are OR in a SQL range. ge and le are one window, so they become one BT.
    DATA lv_low_count TYPE i.
    DATA lv_high_count TYPE i.
    DATA lv_other TYPE i.
    DATA lv_from TYPE string.
    DATA lv_to TYPE string.
    DATA lv_from_option TYPE string.
    DATA lv_to_option TYPE string.
    LOOP AT lt_include INTO DATA(ls_include).
      CASE ls_include-option.
        WHEN 'EQ' OR 'BT'.
          lv_other = lv_other + 1.
        WHEN 'GE' OR 'GT'.
          lv_low_count = lv_low_count + 1.
          lv_from = ls_include-low.
          lv_from_option = ls_include-option.
        WHEN 'LE' OR 'LT'.
          lv_high_count = lv_high_count + 1.
          lv_to = ls_include-low.
          lv_to_option = ls_include-option.
      ENDCASE.
    ENDLOOP.

    IF lv_other = 0 AND lv_low_count = 1 AND lv_high_count = 1.
      DATA lv_start TYPE d.
      DATA lv_end TYPE d.
      lv_start = lv_from.
      lv_end = lv_to.
      IF lv_from_option = 'GT'.
        lv_start = lv_start + 1.
      ENDIF.
      IF lv_to_option = 'LT'.
        lv_end = lv_end - 1.
      ENDIF.
      APPEND VALUE #(
        sign   = 'I'
        option = 'BT'
        low    = lv_start
        high   = lv_end ) TO rt_range.
    ELSE.
      APPEND LINES OF lt_include TO rt_range.
    ENDIF.
    APPEND LINES OF lt_exclude TO rt_range.
  ENDMETHOD.

  METHOD timestamp_selection.
    DATA(lt_date) = date_selection( it_range = it_range iv_name = iv_name ).
    LOOP AT lt_date INTO DATA(ls_date).
      DATA(lv_option) = to_upper( ls_date-option ).
      IF lv_option = 'EQ' AND ls_date-low IS NOT INITIAL.
        APPEND VALUE #(
          sign   = ls_date-sign
          option = 'BT'
          low    = ls_date-low && '000000'
          high   = ls_date-low && '235959' ) TO rt_range.
      ELSEIF lv_option = 'BT'.
        APPEND VALUE #(
          sign   = ls_date-sign
          option = 'BT'
          low    = ls_date-low && '000000'
          high   = ls_date-high && '235959' ) TO rt_range.
      ELSEIF lv_option = 'GE'.
        APPEND VALUE #( sign = ls_date-sign option = 'GE' low = ls_date-low && '000000' ) TO rt_range.
      ELSEIF lv_option = 'GT'.
        APPEND VALUE #( sign = ls_date-sign option = 'GT' low = ls_date-low && '235959' ) TO rt_range.
      ELSEIF lv_option = 'LE'.
        APPEND VALUE #( sign = ls_date-sign option = 'LE' low = ls_date-low && '235959' ) TO rt_range.
      ELSEIF lv_option = 'LT'.
        APPEND VALUE #( sign = ls_date-sign option = 'LT' low = ls_date-low && '000000' ) TO rt_range.
      ELSE.
        APPEND ls_date TO rt_range.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD access_date_selection.
    TRY.
        rt_range = date_selection( it_range = it_range iv_name = iv_name ).
      CATCH zcx_sec_settings INTO DATA(lx_settings).
        raise_as_access( lx_settings ).
    ENDTRY.
  ENDMETHOD.

  METHOD access_timestamp_selection.
    TRY.
        rt_range = timestamp_selection( it_range = it_range iv_name = iv_name ).
      CATCH zcx_sec_settings INTO DATA(lx_settings).
        raise_as_access( lx_settings ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
