CLASS zcl_sec_pfl_param_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        applicationserver        TYPE c LENGTH 64,
        parametername            TYPE string,
        kerneldefaultvalueraw    TYPE string,
        kerneldefaultvalue       TYPE string,
        instanceprofilevalue     TYPE string,
        description              TYPE string,
        parametertype            TYPE i,
        unit                     TYPE string,
        restrictionvalues        TYPE string,
        dynamicallychangeable    TYPE c LENGTH 1,
        parameterstatus          TYPE i,
        statustext               TYPE string,
        securityrelevant         TYPE c LENGTH 1,
        securityarea             TYPE c LENGTH 20,
        systemid                 TYPE c LENGTH 8,
      END OF ty_row,
      tt_row TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

    METHODS constructor
      IMPORTING
        io_source TYPE REF TO zif_sec_pfl_param_source OPTIONAL
        io_auth   TYPE REF TO zif_sec_auth OPTIONAL.

    METHODS read_rows
      RETURNING
        VALUE(rt_rows) TYPE tt_row
      RAISING
        zcx_sec_settings.

  PRIVATE SECTION.
    DATA mo_source TYPE REF TO zif_sec_pfl_param_source.
    DATA mo_auth TYPE REF TO zif_sec_auth.

    METHODS flag
      IMPORTING
        iv_yes         TYPE abap_bool
      RETURNING
        VALUE(rv_flag) TYPE abap_bool.
ENDCLASS.


CLASS zcl_sec_pfl_param_query IMPLEMENTATION.
  METHOD constructor.
    mo_source = io_source.
    mo_auth = io_auth.
    IF mo_source IS NOT BOUND.
      mo_source = NEW zcl_sec_pfl_param_source( ).
    ENDIF.
    IF mo_auth IS NOT BOUND.
      mo_auth = NEW zcl_sec_auth( ).
    ENDIF.
  ENDMETHOD.

  METHOD flag.
    rv_flag = COND #( WHEN iv_yes = abap_true THEN 'X' ELSE ' ' ).
  ENDMETHOD.

  METHOD read_rows.
    mo_auth->check_profile_display( ).
    DATA(lt_parameters) = mo_source->read( ).

    LOOP AT lt_parameters INTO DATA(ls_parameter).
      DATA(ls_class) = zcl_sec_pfl_param_classify=>classify( ls_parameter-name ).
      APPEND VALUE ty_row(
        applicationserver     = ls_parameter-application_server
        parametername         = ls_parameter-name
        kerneldefaultvalueraw = ls_parameter-default_value_raw
        kerneldefaultvalue    = ls_parameter-default_value
        instanceprofilevalue  = ls_parameter-user_value
        description           = ls_parameter-description
        parametertype         = ls_parameter-parameter_type
        unit                  = ls_parameter-unit
        restrictionvalues     = ls_parameter-restriction_values
        dynamicallychangeable = flag( ls_parameter-dynamically_changeable )
        parameterstatus       = ls_parameter-state
        statustext            = |{ ls_parameter-state }|
        securityrelevant      = flag( ls_class-relevant )
        securityarea          = ls_class-area
        systemid              = ls_parameter-system_id ) TO rt_rows.
    ENDLOOP.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    DATA(lt_rows) = read_rows( ).
    zcl_sec_query_util=>filter_rows( EXPORTING io_request = io_request CHANGING ct_rows = lt_rows ).

    DATA(lt_sort) = zcl_sec_query_util=>sort_from_request( io_request ).
    zcl_sec_query_util=>sort_by( EXPORTING it_sort = lt_sort CHANGING ct_data = lt_rows ).

    DATA lv_skip TYPE i.
    DATA lv_top TYPE i.
    zcl_sec_query_util=>paging_from_request( EXPORTING io_request = io_request IMPORTING ev_skip = lv_skip ev_top = lv_top ).
    DATA lv_from TYPE i.
    DATA lv_to TYPE i.
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
