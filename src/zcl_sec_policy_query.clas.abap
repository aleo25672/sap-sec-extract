CLASS zcl_sec_policy_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        policyname         TYPE c LENGTH 40,
        client             TYPE mandt,
        description        TYPE c LENGTH 60,
        createdby          TYPE c LENGTH 12,
        createdon          TYPE p LENGTH 8 DECIMALS 0,
        changedby          TYPE c LENGTH 12,
        changedon          TYPE p LENGTH 8 DECIMALS 0,
        assignedusercount  TYPE i,
        userscounted       TYPE c LENGTH 1,
      END OF ty_row,
      tt_row TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

    METHODS constructor
      IMPORTING
        io_auth TYPE REF TO zif_sec_auth OPTIONAL.

  PRIVATE SECTION.
    DATA mo_auth TYPE REF TO zif_sec_auth.
ENDCLASS.


CLASS zcl_sec_policy_query IMPLEMENTATION.
  METHOD constructor.
    mo_auth = io_auth.
    IF mo_auth IS NOT BOUND.
      mo_auth = NEW zcl_sec_auth( ).
    ENDIF.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    mo_auth->check_policy_display( ).
    DATA(lv_count_users) = mo_auth->can_count_users( ).

    SELECT name, created_by, created_on, changed_by, changed_on
      FROM sec_policy_cust
      INTO TABLE @DATA(lt_policy).

    SELECT policy_name, langu, policy_text
      FROM sec_policy_custt
      WHERE langu = @sy-langu OR langu = 'E'
      INTO TABLE @DATA(lt_text).

    TYPES:
      BEGIN OF ty_user_count,
        security_policy TYPE c LENGTH 40,
        user_count      TYPE i,
      END OF ty_user_count.
    DATA lt_counts TYPE HASHED TABLE OF ty_user_count WITH UNIQUE KEY security_policy.
    IF lv_count_users = abap_true.
      SELECT security_policy, COUNT(*) AS user_count
        FROM usr02
        WHERE security_policy IS NOT INITIAL
        GROUP BY security_policy
        INTO TABLE @lt_counts.
    ENDIF.

    DATA lt_rows TYPE tt_row.
    LOOP AT lt_policy INTO DATA(ls_policy).
      DATA(ls_row) = VALUE ty_row(
        policyname = ls_policy-name
        client     = sy-mandt
        createdby  = ls_policy-created_by
        createdon  = ls_policy-created_on
        changedby  = ls_policy-changed_by
        changedon  = ls_policy-changed_on ).

      READ TABLE lt_text INTO DATA(ls_text)
        WITH KEY policy_name = ls_policy-name langu = sy-langu.
      IF sy-subrc <> 0 AND sy-langu <> 'E'.
        READ TABLE lt_text INTO ls_text
          WITH KEY policy_name = ls_policy-name langu = 'E'.
      ENDIF.
      IF sy-subrc = 0.
        ls_row-description = ls_text-policy_text.
      ENDIF.

      IF lv_count_users = abap_true.
        READ TABLE lt_counts INTO DATA(ls_count) WITH TABLE KEY security_policy = ls_policy-name.
        IF sy-subrc = 0.
          ls_row-assignedusercount = ls_count-user_count.
        ENDIF.
        ls_row-userscounted = 'X'.
      ENDIF.
      APPEND ls_row TO lt_rows.
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
      LOOP AT lt_rows INTO ls_row FROM lv_from TO lv_to.
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
