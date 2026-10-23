CLASS zcl_sec_pfl_param_classify DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_result,
        relevant TYPE abap_bool,
        area     TYPE string,
      END OF ty_result.

    CLASS-METHODS classify
      IMPORTING
        iv_name          TYPE string
      RETURNING
        VALUE(rs_result) TYPE ty_result.
ENDCLASS.


CLASS zcl_sec_pfl_param_classify IMPLEMENTATION.
  METHOD classify.
    TYPES:
      BEGIN OF ty_prefix,
        prefix TYPE string,
        area   TYPE string,
      END OF ty_prefix.

    " Longer prefixes are listed before shorter ones.
    DATA lt_rules TYPE STANDARD TABLE OF ty_prefix WITH EMPTY KEY.
    lt_rules = VALUE #(
      ( prefix = 'system/secure' area = 'SecureStore' )
      ( prefix = 'login/' area = 'Login' )
      ( prefix = 'auth/' area = 'Authentication' )
      ( prefix = 'snc/' area = 'SNC' )
      ( prefix = 'rfc/' area = 'RFC' )
      ( prefix = 'gw/' area = 'Gateway' )
      ( prefix = 'icm/' area = 'ICM' )
      ( prefix = 'ms/' area = 'MessageServer' )
      ( prefix = 'ssl/' area = 'TLS' )
      ( prefix = 'csi/' area = 'CSI' )
      ( prefix = 'ssf/' area = 'SSF' )
      ( prefix = 'rsec/' area = 'SecureStore' )
      ( prefix = 'icf/' area = 'ICF' )
      ( prefix = 'ucon/' area = 'UCON' ) ).

    DATA(lv_name) = to_lower( iv_name ).

    IF lv_name = 'rdisp/gui_auto_logout'.
      rs_result-relevant = abap_true.
      rs_result-area = 'Session'.
      RETURN.
    ENDIF.
    IF lv_name = 'rec/client'.
      rs_result-relevant = abap_true.
      rs_result-area = 'Client'.
      RETURN.
    ENDIF.

    LOOP AT lt_rules INTO DATA(ls_rule).
      DATA(lv_pattern) = |{ ls_rule-prefix }*|.
      IF lv_name CP lv_pattern.
        rs_result-relevant = abap_true.
        rs_result-area = ls_rule-area.
        RETURN.
      ENDIF.
    ENDLOOP.

    rs_result-relevant = abap_false.
    CLEAR rs_result-area.
  ENDMETHOD.
ENDCLASS.
