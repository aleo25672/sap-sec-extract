CLASS zcl_sec_client_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        client                     TYPE mandt,
        clientname                 TYPE c LENGTH 25,
        clientrole                 TYPE c LENGTH 1,
        clientroletext             TYPE c LENGTH 60,
        clientspecificchanges      TYPE c LENGTH 1,
        clientspecificchangestext  TYPE c LENGTH 80,
        crossclientchanges         TYPE c LENGTH 1,
        crossclientchangestext     TYPE c LENGTH 80,
        clientcopyprotection       TYPE c LENGTH 1,
        clientcopyprotectiontext   TYPE c LENGTH 80,
        cattallowed                TYPE c LENGTH 1,
        cattallowedtext            TYPE c LENGTH 80,
        upgradecascadelocked       TYPE c LENGTH 1,
        temporarilylocked          TYPE c LENGTH 1,
        logicalsystem              TYPE c LENGTH 10,
        lastchangedby              TYPE c LENGTH 12,
        lastchangedon              TYPE dats,
        tablechangelogging         TYPE c LENGTH 1,
      END OF ty_row,
      tt_row TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

    METHODS constructor
      IMPORTING
        io_auth TYPE REF TO zif_sec_auth OPTIONAL.

  PRIVATE SECTION.
    DATA mo_auth TYPE REF TO zif_sec_auth.
ENDCLASS.


CLASS zcl_sec_client_query IMPLEMENTATION.
  METHOD constructor.
    mo_auth = io_auth.
    IF mo_auth IS NOT BOUND.
      mo_auth = NEW zcl_sec_auth( ).
    ENDIF.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    mo_auth->check_client_display( ).

    SELECT mandt, mtext, cccategory, cccoractiv, ccnocliind, cccopylock,
           ccimaildis, ccnocascad, cctemplock, logsys, changeuser, changedate
      FROM t000
      INTO TABLE @DATA(lt_client).

    DATA lv_logging TYPE c LENGTH 1.
    SELECT SINGLE protokoll
      FROM dd09l
      WHERE tabname = 'T000'
        AND as4local = 'A'
      INTO @lv_logging.

    DATA lt_rows TYPE tt_row.
    LOOP AT lt_client INTO DATA(ls_client).
      APPEND VALUE ty_row(
        client                    = ls_client-mandt
        clientname                = ls_client-mtext
        clientrole                = ls_client-cccategory
        clientroletext            = zcl_sec_domain_text=>domain_text(
                                      iv_domain = 'CCCATEGORY'
                                      iv_code = ls_client-cccategory
                                      it_fallback = zcl_sec_domain_text=>client_role_fallbacks( ) )
        clientspecificchanges     = ls_client-cccoractiv
        clientspecificchangestext = zcl_sec_domain_text=>domain_text(
                                      iv_domain = 'CCCORACTIV'
                                      iv_code = ls_client-cccoractiv
                                      it_fallback = zcl_sec_domain_text=>client_change_fallbacks( ) )
        crossclientchanges        = ls_client-ccnocliind
        crossclientchangestext    = zcl_sec_domain_text=>domain_text(
                                      iv_domain = 'CCNOCLIIND'
                                      iv_code = ls_client-ccnocliind
                                      it_fallback = zcl_sec_domain_text=>cross_client_fallbacks( ) )
        clientcopyprotection      = ls_client-cccopylock
        clientcopyprotectiontext  = zcl_sec_domain_text=>domain_text(
                                      iv_domain = 'COPYLOCK'
                                      iv_code = ls_client-cccopylock
                                      it_fallback = zcl_sec_domain_text=>copy_lock_fallbacks( ) )
        cattallowed               = ls_client-ccimaildis
        cattallowedtext           = zcl_sec_domain_text=>domain_text(
                                      iv_domain = 'SECURECATT'
                                      iv_code = ls_client-ccimaildis
                                      it_fallback = zcl_sec_domain_text=>catt_fallbacks( ) )
        upgradecascadelocked      = ls_client-ccnocascad
        temporarilylocked         = ls_client-cctemplock
        logicalsystem             = ls_client-logsys
        lastchangedby             = ls_client-changeuser
        lastchangedon             = ls_client-changedate
        tablechangelogging        = lv_logging ) TO lt_rows.
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
