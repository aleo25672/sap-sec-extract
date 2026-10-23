INTERFACE zif_sec_pfl_param_source
  PUBLIC.

  TYPES:
    BEGIN OF ty_parameter,
      name                   TYPE string,
      user_value             TYPE string,
      default_value          TYPE string,
      default_value_raw      TYPE string,
      description            TYPE string,
      parameter_type         TYPE i,
      unit                   TYPE string,
      restriction_values     TYPE string,
      dynamically_changeable TYPE abap_bool,
      state                  TYPE i,
      application_server     TYPE string,
      system_id              TYPE string,
    END OF ty_parameter,
    tt_parameter TYPE STANDARD TABLE OF ty_parameter WITH EMPTY KEY.

  METHODS read
    RETURNING
      VALUE(rt_parameters) TYPE tt_parameter
    RAISING
      zcx_sec_settings.
ENDINTERFACE.
