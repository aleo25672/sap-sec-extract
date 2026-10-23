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
ENDCLASS.
