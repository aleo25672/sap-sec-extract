CLASS zcl_sec_usraddr_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        username       TYPE c LENGTH 12,
        client         TYPE c LENGTH 3,
        firstname      TYPE c LENGTH 40,
        lastname       TYPE c LENGTH 40,
        fullname       TYPE c LENGTH 80,
        emailaddress   TYPE c LENGTH 241,
        department     TYPE c LENGTH 40,
        phoneextension TYPE c LENGTH 10,
        building       TYPE c LENGTH 10,
        room           TYPE c LENGTH 10,
        internalmail   TYPE c LENGTH 10,
        costcenter     TYPE c LENGTH 8,
        companyname    TYPE c LENGTH 40,
        city           TYPE c LENGTH 40,
        postalcode     TYPE c LENGTH 10,
        company        TYPE c LENGTH 42,
      END OF ty_row,
      tt_row TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY,
      BEGIN OF ty_best,
        username   TYPE c LENGTH 12,
        row        TYPE ty_row,
        date_from  TYPE d,
        consnumber TYPE n LENGTH 3,
        preferred  TYPE abap_bool,
      END OF ty_best.

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

    CLASS-METHODS prefer
      IMPORTING
        is_current       TYPE ty_best
        is_candidate     TYPE ty_best
      RETURNING
        VALUE(rv_prefer) TYPE abap_bool.

  PRIVATE SECTION.
    TYPES tt_best TYPE HASHED TABLE OF ty_best WITH UNIQUE KEY username.

    DATA mo_auth TYPE REF TO zif_sec_access_auth.
ENDCLASS.


CLASS zcl_sec_usraddr_query IMPLEMENTATION.
  METHOD constructor.
    mo_auth = io_auth.
    IF mo_auth IS NOT BOUND.
      mo_auth = NEW zcl_sec_access_auth( ).
    ENDIF.
  ENDMETHOD.

  METHOD prefer.
    IF is_current-row-emailaddress IS INITIAL AND is_candidate-row-emailaddress IS NOT INITIAL.
      rv_prefer = abap_true.
      RETURN.
    ENDIF.
    IF is_candidate-preferred = abap_true AND is_current-preferred = abap_false
      AND is_candidate-row-emailaddress IS NOT INITIAL.
      rv_prefer = abap_true.
      RETURN.
    ENDIF.
    IF is_candidate-preferred = is_current-preferred
      AND is_candidate-date_from > is_current-date_from.
      rv_prefer = abap_true.
      RETURN.
    ENDIF.
    IF is_candidate-preferred = is_current-preferred
      AND is_candidate-date_from = is_current-date_from
      AND is_candidate-consnumber > is_current-consnumber.
      rv_prefer = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD read_rows.
    mo_auth->check_user_display( ).
    IF io_request IS NOT BOUND.
      RETURN.
    ENDIF.

    " USER_ADDR is the SE16 view. ADR6 supplies the email, which the view does not carry.
    SELECT a~bname, a~name_first, a~name_last, a~name_textc,
           a~tel_extens, a~kostl, a~building, a~roomnumber,
           a~department, a~inhouse_ml, a~name1, a~city1, a~post_code1, a~company,
           e~date_from, e~consnumber, e~flgdefault, e~smtp_addr
      FROM user_addr AS a
      LEFT OUTER JOIN usr21 AS u
        ON u~bname = a~bname
      LEFT OUTER JOIN adr6 AS e
        ON e~addrnumber = u~addrnumber
       AND e~persnumber = u~persnumber
       AND e~date_from <= @sy-datum
      INTO TABLE @DATA(lt_addr).

    DATA lt_best TYPE tt_best.
    LOOP AT lt_addr INTO DATA(ls_addr).
      DATA(ls_candidate) = VALUE ty_best(
        username   = ls_addr-bname
        date_from  = ls_addr-date_from
        consnumber = ls_addr-consnumber
        preferred  = xsdbool( ls_addr-flgdefault = 'X' )
        row        = VALUE ty_row(
          username       = ls_addr-bname
          client         = sy-mandt
          firstname      = ls_addr-name_first
          lastname       = ls_addr-name_last
          fullname       = ls_addr-name_textc
          emailaddress   = ls_addr-smtp_addr
          department     = ls_addr-department
          phoneextension = ls_addr-tel_extens
          building       = ls_addr-building
          room           = ls_addr-roomnumber
          internalmail   = ls_addr-inhouse_ml
          costcenter     = ls_addr-kostl
          companyname    = ls_addr-name1
          city           = ls_addr-city1
          postalcode     = ls_addr-post_code1
          company        = ls_addr-company ) ).
      READ TABLE lt_best ASSIGNING FIELD-SYMBOL(<best>)
        WITH TABLE KEY username = ls_candidate-username.
      IF sy-subrc <> 0.
        INSERT ls_candidate INTO TABLE lt_best.
      ELSEIF prefer( is_current = <best> is_candidate = ls_candidate ) = abap_true.
        <best> = ls_candidate.
      ENDIF.
    ENDLOOP.

    LOOP AT lt_best INTO DATA(ls_best).
      APPEND ls_best-row TO rt_rows.
    ENDLOOP.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    DATA(lt_rows) = read_rows( io_request ).
    zcl_sec_query_util=>apply_access(
      EXPORTING io_request = io_request io_response = io_response
      CHANGING ct_rows = lt_rows ).
  ENDMETHOD.
ENDCLASS.
