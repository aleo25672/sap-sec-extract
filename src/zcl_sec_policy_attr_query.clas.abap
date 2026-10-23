CLASS zcl_sec_policy_attr_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        policyname       TYPE c LENGTH 40,
        attributename    TYPE c LENGTH 40,
        valueorigin      TYPE c LENGTH 13,
        effectivevalue   TYPE i,
        defaultvalue     TYPE i,
        profileparameter TYPE c LENGTH 60,
        description      TYPE c LENGTH 60,
        client           TYPE mandt,
      END OF ty_row,
      tt_row TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

    METHODS constructor
      IMPORTING
        io_auth TYPE REF TO zif_sec_auth OPTIONAL.

  PRIVATE SECTION.
    DATA mo_auth TYPE REF TO zif_sec_auth.
ENDCLASS.


CLASS zcl_sec_policy_attr_query IMPLEMENTATION.
  METHOD constructor.
    mo_auth = io_auth.
    IF mo_auth IS NOT BOUND.
      mo_auth = NEW zcl_sec_auth( ).
    ENDIF.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    mo_auth->check_policy_display( ).

    SELECT name
      FROM sec_policy_cust
      INTO TABLE @DATA(lt_policy).

    SELECT name, default_value, ddic_dataelement, redeemed_profile_parameter
      FROM sec_policy_attr
      INTO TABLE @DATA(lt_attr).

    SELECT name, attrib_key, attrib_value
      FROM sec_policy_rt
      INTO TABLE @DATA(lt_stored).

    TYPES:
      BEGIN OF ty_element_text,
        rollname   TYPE dd04t-rollname,
        ddlanguage TYPE dd04t-ddlanguage,
        ddtext     TYPE dd04t-ddtext,
      END OF ty_element_text.
    DATA lt_element_text TYPE STANDARD TABLE OF ty_element_text WITH EMPTY KEY.
    DATA lt_elements TYPE STANDARD TABLE OF dd04t-rollname WITH EMPTY KEY.
    LOOP AT lt_attr INTO DATA(ls_element).
      IF ls_element-ddic_dataelement IS NOT INITIAL.
        APPEND ls_element-ddic_dataelement TO lt_elements.
      ENDIF.
    ENDLOOP.
    SORT lt_elements.
    DELETE ADJACENT DUPLICATES FROM lt_elements.
    IF lt_elements IS NOT INITIAL.
      SELECT rollname, ddlanguage, ddtext
        FROM dd04t
        FOR ALL ENTRIES IN @lt_elements
        WHERE rollname = @lt_elements-table_line
          AND as4local = 'A'
          AND ( ddlanguage = @sy-langu OR ddlanguage = 'E' )
        INTO TABLE @lt_element_text.
    ENDIF.

    DATA lt_rows TYPE tt_row.
    LOOP AT lt_policy INTO DATA(ls_policy).
      LOOP AT lt_attr INTO DATA(ls_attr).
        DATA(lv_persisted) = abap_false.
        DATA lv_stored TYPE i.
        CLEAR lv_stored.
        READ TABLE lt_stored INTO DATA(ls_stored)
          WITH KEY name = ls_policy-name
                   attrib_key = ls_attr-name.
        IF sy-subrc = 0.
          lv_persisted = abap_true.
          lv_stored = ls_stored-attrib_value.
        ENDIF.

        DATA lv_description TYPE dd04t-ddtext.
        CLEAR lv_description.
        IF ls_attr-ddic_dataelement IS NOT INITIAL.
          READ TABLE lt_element_text INTO DATA(ls_element_text)
            WITH KEY rollname = ls_attr-ddic_dataelement ddlanguage = sy-langu.
          IF sy-subrc <> 0 AND sy-langu <> 'E'.
            READ TABLE lt_element_text INTO ls_element_text
              WITH KEY rollname = ls_attr-ddic_dataelement ddlanguage = 'E'.
          ENDIF.
          IF sy-subrc = 0.
            lv_description = ls_element_text-ddtext.
          ENDIF.
        ENDIF.

        APPEND VALUE ty_row(
          policyname       = ls_policy-name
          attributename    = ls_attr-name
          valueorigin      = zcl_sec_policy_derive=>origin( lv_persisted )
          effectivevalue   = zcl_sec_policy_derive=>effective(
                               iv_persisted = lv_persisted
                               iv_stored    = lv_stored
                               iv_default   = ls_attr-default_value )
          defaultvalue     = ls_attr-default_value
          profileparameter = ls_attr-redeemed_profile_parameter
          description      = lv_description
          client           = sy-mandt ) TO lt_rows.
      ENDLOOP.
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
