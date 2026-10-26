CLASS zcl_sec_user_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        userid                  TYPE c LENGTH 12,
        client                  TYPE mandt,
        usertype                TYPE c LENGTH 1,
        usertypetext            TYPE c LENGTH 60,
        usergroup               TYPE c LENGTH 12,
        validfrom               TYPE dats,
        validto                 TYPE dats,
        lockflag                TYPE i,
        globallylocked          TYPE c LENGTH 1,
        locallylocked           TYPE c LENGTH 1,
        failedlogonlocked       TYPE c LENGTH 1,
        passwordstate           TYPE i,
        passwordstatetext       TYPE c LENGTH 80,
        passwordhashversion     TYPE c LENGTH 1,
        passwordhashversiontext TYPE c LENGTH 40,
        lastlogondate           TYPE dats,
        lastlogontime           TYPE tims,
        createdby               TYPE c LENGTH 12,
        createdon               TYPE dats,
        securitypolicy          TYPE c LENGTH 40,
        referenceuser           TYPE c LENGTH 12,
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


CLASS zcl_sec_user_query IMPLEMENTATION.
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
    DATA(lt_raw) = mo_source->read_users( ).
    LOOP AT lt_raw INTO DATA(ls_raw).
      DATA(ls_lock) = zcl_sec_user_derive=>locks( ls_raw-lockflag ).
      APPEND VALUE ty_row(
        userid                  = ls_raw-userid
        client                  = sy-mandt
        usertype                = ls_raw-usertype
        usertypetext            = zcl_sec_user_derive=>user_type_text( ls_raw-usertype )
        usergroup               = ls_raw-usergroup
        validfrom               = ls_raw-validfrom
        validto                 = ls_raw-validto
        lockflag                = ls_raw-lockflag
        globallylocked          = ls_lock-globally_locked
        locallylocked           = ls_lock-locally_locked
        failedlogonlocked       = ls_lock-failed_logon_locked
        passwordstate           = ls_raw-passwordstate
        passwordstatetext       = zcl_sec_user_derive=>password_state_text( CONV i( ls_raw-passwordstate ) )
        passwordhashversion     = ls_raw-passwordhashversion
        passwordhashversiontext = zcl_sec_user_derive=>hash_version_text( ls_raw-passwordhashversion )
        lastlogondate           = ls_raw-lastlogondate
        lastlogontime           = ls_raw-lastlogontime
        createdby               = ls_raw-createdby
        createdon               = ls_raw-createdon
        securitypolicy          = ls_raw-securitypolicy
        referenceuser           = ls_raw-referenceuser ) TO rt_rows.
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
