CLASS zcl_sec_syschg_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        settingscope     TYPE c LENGTH 20,
        objectname       TYPE c LENGTH 30,
        changeoption     TYPE c LENGTH 1,
        changeoptiontext TYPE c LENGTH 60,
      END OF ty_row,
      tt_row TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

    METHODS constructor
      IMPORTING
        io_auth TYPE REF TO zif_sec_auth OPTIONAL.

  PRIVATE SECTION.
    DATA mo_auth TYPE REF TO zif_sec_auth.
ENDCLASS.


CLASS zcl_sec_syschg_query IMPLEMENTATION.
  METHOD constructor.
    mo_auth = io_auth.
    IF mo_auth IS NOT BOUND.
      mo_auth = NEW zcl_sec_auth( ).
    ENDIF.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    mo_auth->check_system_change_display( ).

    DATA lt_rows TYPE tt_row.
    DATA lv_global TYPE tadir-edtflag.
    SELECT SINGLE edtflag
      FROM tadir
      WHERE pgmid = 'HEAD'
        AND object = 'SYST'
        AND obj_name = @space
      INTO @lv_global.

    APPEND VALUE ty_row(
      settingscope     = 'Global'
      objectname       = ''
      changeoption     = lv_global
      changeoptiontext = zcl_sec_domain_text=>global_change_text( lv_global ) ) TO lt_rows.

    SELECT dlvunit, changeable
      FROM dlv_systc
      INTO TABLE @DATA(lt_component).
    LOOP AT lt_component INTO DATA(ls_component).
      APPEND VALUE ty_row(
        settingscope     = 'SoftwareComponent'
        objectname       = ls_component-dlvunit
        changeoption     = ls_component-changeable
        changeoptiontext = zcl_sec_domain_text=>domain_text(
                             iv_domain = 'DLV_CHANGE'
                             iv_code = ls_component-changeable
                             it_fallback = zcl_sec_domain_text=>component_fallbacks( ) ) ) TO lt_rows.
    ENDLOOP.

    SELECT namespace, editflag
      FROM trnspace
      INTO TABLE @DATA(lt_namespace).
    LOOP AT lt_namespace INTO DATA(ls_namespace).
      APPEND VALUE ty_row(
        settingscope     = 'Namespace'
        objectname       = ls_namespace-namespace
        changeoption     = ls_namespace-editflag
        changeoptiontext = zcl_sec_domain_text=>namespace_change_text( ls_namespace-editflag ) ) TO lt_rows.
    ENDLOOP.

    zcl_sec_query_util=>filter_rows( EXPORTING io_request = io_request CHANGING ct_rows = lt_rows ).

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
      LOOP AT lt_rows INTO DATA(ls_row) FROM lv_from TO lv_to.
        APPEND ls_row TO lt_page.
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
