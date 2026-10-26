CLASS zcl_sec_prof_assign_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        userid         TYPE c LENGTH 12,
        profilename    TYPE c LENGTH 12,
        profilesource  TYPE c LENGTH 13,
        client         TYPE mandt,
        referenceuser  TYPE c LENGTH 12,
      END OF ty_row,
      tt_row TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

    METHODS constructor
      IMPORTING
        io_source TYPE REF TO zif_sec_access_source OPTIONAL
        io_auth   TYPE REF TO zif_sec_access_auth OPTIONAL.

    METHODS read_rows
      RETURNING
        VALUE(rt_rows) TYPE tt_row
      RAISING
        zcx_sec_access.

  PRIVATE SECTION.
    DATA mo_source TYPE REF TO zif_sec_access_source.
    DATA mo_auth TYPE REF TO zif_sec_access_auth.
ENDCLASS.


CLASS zcl_sec_prof_assign_query IMPLEMENTATION.
  METHOD constructor.
    mo_source = io_source.
    mo_auth = io_auth.
    IF mo_source IS NOT BOUND.
      mo_source = NEW zcl_sec_access_db( ).
    ENDIF.
    IF mo_auth IS NOT BOUND.
      mo_auth = NEW zcl_sec_access_auth( ).
    ENDIF.
  ENDMETHOD.

  METHOD read_rows.
    mo_auth->check_user_display( ).
    mo_auth->check_profile_display( ).
    DATA(lt_raw) = mo_source->read_profile_assignments( ).
    LOOP AT lt_raw INTO DATA(ls_raw).
      APPEND VALUE ty_row(
        userid        = ls_raw-userid
        profilename   = ls_raw-profilename
        profilesource = ls_raw-profilesource
        client        = sy-mandt
        referenceuser = ls_raw-referenceuser ) TO rt_rows.
    ENDLOOP.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    DATA(lt_rows) = read_rows( ).

    TRY.
        zcl_sec_query_util=>filter_rows( EXPORTING io_request = io_request CHANGING ct_rows = lt_rows ).
      CATCH zcx_sec_settings INTO DATA(lx_settings).
        RAISE EXCEPTION TYPE zcx_sec_access
          EXPORTING
            textid      = zcx_sec_access=>filter_not_supported
            filter_name = lx_settings->filter_name.
    ENDTRY.

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
ENDCLASS.
