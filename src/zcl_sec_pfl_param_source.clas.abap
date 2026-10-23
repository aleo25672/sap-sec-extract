CLASS zcl_sec_pfl_param_source DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_sec_pfl_param_source.
ENDCLASS.


CLASS zcl_sec_pfl_param_source IMPLEMENTATION.
  METHOD zif_sec_pfl_param_source~read.
    DATA lt_sub_raw TYPE spfl_parameter_list_t.
    DATA lt_usub_raw TYPE spfl_parameter_list_t.
    DATA lt_meta_raw TYPE spfl_parameter_metadata_list_t.
    DATA lt_sub TYPE STANDARD TABLE OF spfl_parameter_list WITH EMPTY KEY.
    DATA lt_usub TYPE STANDARD TABLE OF spfl_parameter_list WITH EMPTY KEY.
    DATA lt_meta TYPE STANDARD TABLE OF spfl_parameter_metadata WITH EMPTY KEY.

    DATA(lv_rc) = cl_spfl_profile_parameter=>get_all_parameter(
      IMPORTING
        parameter_sub  = lt_sub_raw
        parameter_usub = lt_usub_raw ).
    IF lv_rc <> 0.
      RAISE EXCEPTION TYPE zcx_sec_settings
        EXPORTING
          textid = zcx_sec_settings=>profile_read_failed.
    ENDIF.

    lv_rc = cl_spfl_profile_parameter=>get_all_metadata(
      IMPORTING
        metadata = lt_meta_raw ).
    IF lv_rc <> 0.
      RAISE EXCEPTION TYPE zcx_sec_settings
        EXPORTING
          textid = zcx_sec_settings=>profile_read_failed.
    ENDIF.

    lt_sub = lt_sub_raw.
    lt_usub = lt_usub_raw.
    lt_meta = lt_meta_raw.

    DATA lv_server TYPE spfl_parameter_value.
    cl_spfl_profile_parameter=>get_value(
      EXPORTING
        name  = 'rdisp/myname'
      IMPORTING
        value = lv_server ).
    IF lv_server IS INITIAL.
      lv_server = sy-host.
    ENDIF.

    LOOP AT lt_sub INTO DATA(ls_sub).
      DATA(ls_row) = VALUE zif_sec_pfl_param_source=>ty_parameter(
        name               = ls_sub-name
        user_value         = ls_sub-user_value
        default_value      = ls_sub-default_value
        state              = ls_sub-state
        application_server = lv_server
        system_id          = sy-sysid ).

      READ TABLE lt_usub INTO DATA(ls_usub) WITH KEY name = ls_sub-name.
      IF sy-subrc = 0.
        ls_row-default_value_raw = ls_usub-default_value.
      ENDIF.

      READ TABLE lt_meta INTO DATA(ls_meta) WITH KEY name = ls_sub-name.
      IF sy-subrc = 0.
        ls_row-description = ls_meta-description.
        ls_row-parameter_type = ls_meta-type.
        ls_row-unit = ls_meta-unit.
        ls_row-restriction_values = ls_meta-restriction_values.
        ls_row-dynamically_changeable = xsdbool( ls_meta-is_dynamic = 'X' OR ls_meta-is_dynamic = '1' ).
      ENDIF.

      APPEND ls_row TO rt_parameters.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
