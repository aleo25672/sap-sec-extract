CLASS zcl_sec_snc_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        username         TYPE c LENGTH 12,
        client           TYPE c LENGTH 3,
        sncname          TYPE c LENGTH 255,
        guipasswordlogon TYPE c LENGTH 1,
        securitysystem   TYPE c LENGTH 8,
        createdby        TYPE c LENGTH 12,
        createdon        TYPE d,
        createdat        TYPE t,
        changedby        TYPE c LENGTH 12,
        changedon        TYPE d,
        changedat        TYPE t,
      END OF ty_row,
      tt_row TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

    METHODS constructor
      IMPORTING
        io_auth TYPE REF TO zif_sec_access_auth OPTIONAL.

    METHODS read_rows
      IMPORTING
        io_request     TYPE REF TO if_rap_query_request OPTIONAL
      RETURNING
        VALUE(rt_rows) TYPE tt_row
      RAISING
        zcx_sec_access.

  PRIVATE SECTION.
    DATA mo_auth TYPE REF TO zif_sec_access_auth.
ENDCLASS.


CLASS zcl_sec_snc_query IMPLEMENTATION.
  METHOD constructor.
    mo_auth = io_auth.
    IF mo_auth IS NOT BOUND.
      mo_auth = NEW zcl_sec_access_auth( ).
    ENDIF.
  ENDMETHOD.

  METHOD read_rows.
    mo_auth->check_user_display( ).
    IF io_request IS NOT BOUND.
      RETURN.
    ENDIF.

    " HNAME, CHKVAL, and KNAME stay in USRACL. PNAME is the printable SNC name.
    SELECT bname, snc_sid, guiflag, pname, cname, cdate, ctime, mname, mdate, mtime
      FROM usracl
      INTO TABLE @DATA(lt_snc).

    LOOP AT lt_snc INTO DATA(ls_snc).
      APPEND VALUE ty_row(
        username         = ls_snc-bname
        client           = sy-mandt
        sncname          = ls_snc-pname
        guipasswordlogon = ls_snc-guiflag
        securitysystem   = ls_snc-snc_sid
        createdby        = ls_snc-cname
        createdon        = ls_snc-cdate
        createdat        = ls_snc-ctime
        changedby        = ls_snc-mname
        changedon        = ls_snc-mdate
        changedat        = ls_snc-mtime ) TO rt_rows.
    ENDLOOP.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    DATA(lt_rows) = read_rows( io_request ).
    zcl_sec_query_util=>apply_access(
      EXPORTING io_request = io_request io_response = io_response
      CHANGING ct_rows = lt_rows ).
  ENDMETHOD.
ENDCLASS.
