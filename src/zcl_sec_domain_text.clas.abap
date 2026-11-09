CLASS zcl_sec_domain_text DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_value,
        code TYPE string,
        text TYPE string,
      END OF ty_value,
      tt_value TYPE STANDARD TABLE OF ty_value WITH EMPTY KEY.

    CLASS-METHODS from_list
      IMPORTING
        iv_code        TYPE csequence
        it_values      TYPE tt_value
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS domain_text
      IMPORTING
        iv_domain      TYPE csequence
        iv_code        TYPE csequence
        it_fallback    TYPE tt_value OPTIONAL
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS global_change_text
      IMPORTING
        iv_code        TYPE csequence
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS namespace_change_text
      IMPORTING
        iv_code        TYPE csequence
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS component_fallbacks
      RETURNING
        VALUE(rt_values) TYPE tt_value.

    CLASS-METHODS client_role_fallbacks
      RETURNING
        VALUE(rt_values) TYPE tt_value.

    CLASS-METHODS client_change_fallbacks
      RETURNING
        VALUE(rt_values) TYPE tt_value.

    CLASS-METHODS cross_client_fallbacks
      RETURNING
        VALUE(rt_values) TYPE tt_value.

    CLASS-METHODS copy_lock_fallbacks
      RETURNING
        VALUE(rt_values) TYPE tt_value.

    CLASS-METHODS catt_fallbacks
      RETURNING
        VALUE(rt_values) TYPE tt_value.

    CLASS-METHODS component_type_fallbacks
      RETURNING
        VALUE(rt_values) TYPE tt_value.

    CLASS-METHODS program_type_fallbacks
      RETURNING
        VALUE(rt_values) TYPE tt_value.

    CLASS-METHODS batch_session_text
      IMPORTING
        iv_code        TYPE csequence
      RETURNING
        VALUE(rv_text) TYPE string.
ENDCLASS.


CLASS zcl_sec_domain_text IMPLEMENTATION.
  METHOD from_list.
    DATA(lv_code) = condense( to_upper( iv_code ) ).
    LOOP AT it_values INTO DATA(ls_value).
      IF condense( to_upper( ls_value-code ) ) = lv_code.
        rv_text = ls_value-text.
        RETURN.
      ENDIF.
    ENDLOOP.
    rv_text = iv_code.
  ENDMETHOD.

  METHOD domain_text.
    DATA lv_domain TYPE string.
    DATA lv_code TYPE string.
    DATA lv_text TYPE dd07t-ddtext.
    lv_domain = iv_domain.
    lv_code = iv_code.
    SELECT SINGLE ddtext
      FROM dd07t
      WHERE domname = @lv_domain
        AND ddlanguage = @sy-langu
        AND as4local = 'A'
        AND domvalue_l = @lv_code
      INTO @lv_text.
    IF sy-subrc <> 0 AND sy-langu <> 'E'.
      SELECT SINGLE ddtext
        FROM dd07t
        WHERE domname = @lv_domain
          AND ddlanguage = 'E'
          AND as4local = 'A'
          AND domvalue_l = @lv_code
        INTO @lv_text.
    ENDIF.
    IF sy-subrc = 0 AND lv_text IS NOT INITIAL.
      rv_text = lv_text.
      RETURN.
    ENDIF.
    rv_text = from_list( iv_code = iv_code it_values = it_fallback ).
  ENDMETHOD.

  METHOD global_change_text.
    CASE to_upper( condense( iv_code ) ).
      WHEN ''.
        rv_text = 'Modifiable'.
      WHEN 'N'.
        rv_text = 'Not modifiable'.
      WHEN OTHERS.
        rv_text = iv_code.
    ENDCASE.
  ENDMETHOD.

  METHOD namespace_change_text.
    DATA(lv_code) = condense( iv_code ).
    IF to_upper( lv_code ) = 'X'.
      rv_text = 'Modifiable'.
    ELSEIF lv_code IS INITIAL.
      rv_text = 'Not modifiable'.
    ELSE.
      rv_text = lv_code.
    ENDIF.
  ENDMETHOD.

  METHOD component_fallbacks.
    rt_values = VALUE #(
      ( code = 'F' text = 'Modifiable' )
      ( code = 'R' text = 'Restricted modifiability' )
      ( code = 'E' text = 'Not modifiable, enhancements still allowed' )
      ( code = 'N' text = 'Not modifiable, enhancements not allowed' ) ).
  ENDMETHOD.

  METHOD client_role_fallbacks.
    rt_values = VALUE #(
      ( code = 'P' text = 'Production' )
      ( code = 'T' text = 'Test' )
      ( code = 'C' text = 'Customizing' )
      ( code = 'D' text = 'Demo' )
      ( code = 'E' text = 'Training' )
      ( code = 'S' text = 'SAP reference' ) ).
  ENDMETHOD.

  METHOD client_change_fallbacks.
    rt_values = VALUE #(
      ( code = '' text = 'Changes allowed, no automatic recording' )
      ( code = '1' text = 'Changes recorded in a transport' )
      ( code = '2' text = 'No changes allowed' )
      ( code = '3' text = 'Changes allowed, transports out of the client not allowed' ) ).
  ENDMETHOD.

  METHOD cross_client_fallbacks.
    rt_values = VALUE #(
      ( code = '' text = 'Repository and cross-client customizing allowed' )
      ( code = '1' text = 'No cross-client customizing' )
      ( code = '2' text = 'No repository changes' )
      ( code = '3' text = 'No repository and no cross-client customizing' ) ).
  ENDMETHOD.

  METHOD copy_lock_fallbacks.
    rt_values = VALUE #(
      ( code = '' text = 'No restriction' )
      ( code = 'X' text = 'No overwriting' )
      ( code = 'L' text = 'No overwriting and no external availability' ) ).
  ENDMETHOD.

  METHOD catt_fallbacks.
    rt_values = VALUE #(
      ( code = '' text = 'eCATT and CATT not allowed' )
      ( code = 'X' text = 'eCATT and CATT allowed' )
      ( code = 'T' text = 'eCATT and CATT allowed for trusted RFC only' )
      ( code = 'E' text = 'eCATT allowed, FUN/ABAP and CATT not allowed' )
      ( code = 'F' text = 'eCATT allowed, FUN/ABAP and CATT only for trusted RFC' ) ).
  ENDMETHOD.

  METHOD component_type_fallbacks.
    rt_values = VALUE #(
      ( code = '' text = 'Main component' )
      ( code = 'A' text = 'Add-on component' )
      ( code = 'S' text = 'NetWeaver basis component' )
      ( code = 'X' text = 'NetWeaver plug-in' )
      ( code = 'W' text = 'NetWeaver add-on' )
      ( code = 'V' text = 'Application platform component' )
      ( code = 'R' text = 'Application component' )
      ( code = 'P' text = 'Application plug-in' )
      ( code = 'O' text = 'Common application objects' )
      ( code = 'N' text = 'Application extensions' )
      ( code = 'I' text = 'Industry solution, layer 1' )
      ( code = 'H' text = 'Industry solution, layer 2' )
      ( code = 'G' text = 'Industry solution, layer 3' )
      ( code = 'F' text = 'Industry solution, layer 4' )
      ( code = 'E' text = 'Industry solution, layer 5' )
      ( code = 'C' text = 'Project' ) ).
  ENDMETHOD.

  METHOD program_type_fallbacks.
    rt_values = VALUE #(
      ( code = '1' text = 'Executable program' )
      ( code = 'I' text = 'Include' )
      ( code = 'M' text = 'Module pool' )
      ( code = 'F' text = 'Function group' )
      ( code = 'S' text = 'Subroutine pool' )
      ( code = 'J' text = 'Interface pool' )
      ( code = 'K' text = 'Class pool' )
      ( code = 'T' text = 'Type pool' ) ).
  ENDMETHOD.

  METHOD batch_session_text.
    CASE to_upper( condense( iv_code ) ).
      WHEN ''.
        rv_text = 'To be processed'.
      WHEN 'C'.
        rv_text = 'Creating'.
      WHEN 'E'.
        rv_text = 'Incorrect'.
      WHEN 'F'.
        rv_text = 'Finished'.
      WHEN 'R'.
        rv_text = 'Processing'.
      WHEN 'S'.
        rv_text = 'In background'.
      WHEN OTHERS.
        rv_text = iv_code.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.
