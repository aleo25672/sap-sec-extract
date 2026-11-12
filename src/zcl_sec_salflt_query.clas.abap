CLASS zcl_sec_salflt_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        source      TYPE c LENGTH 7,
        hostname    TYPE c LENGTH 32,
        profilename TYPE c LENGTH 8,
        slotnumber  TYPE n LENGTH 4,
        linekind    TYPE c LENGTH 5,
        linevalue   TYPE c LENGTH 20,
        client      TYPE c LENGTH 3,
        username    TYPE c LENGTH 12,
        slotstatus  TYPE c LENGTH 1,
      END OF ty_row,
      tt_row TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

    CLASS-METHODS message_ids
      IMPORTING
        iv_vector     TYPE xstring
      RETURNING
        VALUE(rt_ids) TYPE string_table.

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

    METHODS static_rows
      RETURNING
        VALUE(rt_rows) TYPE tt_row.

    METHODS dynamic_rows
      RETURNING
        VALUE(rt_rows) TYPE tt_row.

    METHODS class_names
      IMPORTING
        iv_classes       TYPE i
      RETURNING
        VALUE(rt_names)  TYPE string_table.

    METHODS append_lines
      IMPORTING
        iv_source      TYPE csequence
        iv_host        TYPE csequence
        iv_profile     TYPE csequence
        iv_slot        TYPE numeric
        iv_client      TYPE csequence
        iv_user        TYPE csequence
        iv_status      TYPE csequence
        iv_vector      TYPE xstring
        iv_detailed    TYPE abap_bool
        it_classes     TYPE string_table
      CHANGING
        ct_rows        TYPE tt_row.
ENDCLASS.


CLASS zcl_sec_salflt_query IMPLEMENTATION.
  METHOD constructor.
    mo_auth = io_auth.
    IF mo_auth IS NOT BOUND.
      mo_auth = NEW zcl_sec_access_auth( ).
    ENDIF.
  ENDMETHOD.

  METHOD message_ids.
    " One byte per subid 0-9 then A-Z. Bits from the top are areas AU, BU, CU, DU, EU, FU, GU, HU.
    CONSTANTS lc_subid TYPE string VALUE '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'.
    CONSTANTS lc_area TYPE string VALUE 'ABCDEFGH'.
    DATA lv_length TYPE i.
    DATA lv_offset TYPE i.
    DATA lv_byte TYPE x LENGTH 1.
    DATA lv_value TYPE i.
    DATA lv_bit TYPE i.
    DATA lv_area TYPE i.
    DATA lv_id TYPE string.

    lv_length = xstrlen( iv_vector ).
    IF lv_length > 36.
      lv_length = 36.
    ENDIF.
    WHILE lv_offset < lv_length.
      lv_byte = iv_vector+lv_offset(1).
      lv_value = lv_byte.
      lv_bit = 128.
      lv_area = 0.
      WHILE lv_bit >= 1.
        IF ( lv_value DIV lv_bit ) MOD 2 = 1.
          lv_id = substring( val = lc_area off = lv_area len = 1 ) && 'U'
            && substring( val = lc_subid off = lv_offset len = 1 ).
          APPEND lv_id TO rt_ids.
        ENDIF.
        lv_bit = lv_bit DIV 2.
        lv_area = lv_area + 1.
      ENDWHILE.
      lv_offset = lv_offset + 1.
    ENDWHILE.
  ENDMETHOD.

  METHOD class_names.
    DATA lv_bit TYPE i VALUE 1.
    WHILE lv_bit <= 128.
      IF ( iv_classes DIV lv_bit ) MOD 2 = 1.
        CASE lv_bit.
          WHEN 1.
            APPEND 'Other' TO rt_names.
          WHEN 2.
            APPEND 'Logon' TO rt_names.
          WHEN 4.
            APPEND 'Transaction start' TO rt_names.
          WHEN 8.
            APPEND 'Report' TO rt_names.
          WHEN 16.
            APPEND 'RFC logon' TO rt_names.
          WHEN 32.
            APPEND 'User master' TO rt_names.
          WHEN 64.
            APPEND 'System' TO rt_names.
          WHEN 128.
            APPEND 'RFC call' TO rt_names.
        ENDCASE.
      ENDIF.
      lv_bit = lv_bit * 2.
    ENDWHILE.
  ENDMETHOD.

  METHOD append_lines.
    DATA lt_ids TYPE string_table.
    DATA lv_kind TYPE c LENGTH 5.
    DATA lv_value TYPE c LENGTH 20.

    IF iv_detailed = abap_true.
      lt_ids = message_ids( iv_vector ).
      lv_kind = 'Event'.
    ELSE.
      lt_ids = it_classes.
      lv_kind = 'Class'.
    ENDIF.
    IF lt_ids IS INITIAL.
      APPEND VALUE ty_row(
        source      = iv_source
        hostname    = iv_host
        profilename = iv_profile
        slotnumber  = iv_slot
        linekind    = 'Filter'
        client      = iv_client
        username    = iv_user
        slotstatus  = iv_status ) TO ct_rows.
      RETURN.
    ENDIF.

    LOOP AT lt_ids INTO DATA(lv_id).
      CLEAR lv_value.
      lv_value = lv_id.
      APPEND VALUE ty_row(
        source      = iv_source
        hostname    = iv_host
        profilename = iv_profile
        slotnumber  = iv_slot
        linekind    = lv_kind
        linevalue   = lv_value
        client      = iv_client
        username    = iv_user
        slotstatus  = iv_status ) TO ct_rows.
    ENDLOOP.
  ENDMETHOD.

  METHOD static_rows.
    SELECT profname, slotno, classes, client, uname, status, selvar, msgvect
      FROM rsauprof
      INTO TABLE @DATA(lt_profile).

    SELECT profname, slotno, msgvect
      FROM rsauprofex
      INTO TABLE @DATA(lt_extended).

    LOOP AT lt_profile INTO DATA(ls_profile).
      IF ls_profile-slotno = 0
          OR ls_profile-profname = '$KERNEL$'
          OR ls_profile-profname = '$CURPROF$'
          OR ls_profile-profname = '$FLAG$'
          OR ls_profile-profname = '$CONFIG$'.
        CONTINUE.
      ENDIF.

      DATA lv_vector TYPE xstring.
      lv_vector = ls_profile-msgvect.
      READ TABLE lt_extended INTO DATA(ls_extended)
        WITH KEY profname = ls_profile-profname
                 slotno   = ls_profile-slotno.
      IF sy-subrc = 0 AND xstrlen( ls_extended-msgvect ) > 0.
        lv_vector = ls_extended-msgvect.
      ENDIF.

      DATA lv_selector TYPE x LENGTH 1.
      DATA lv_selector_value TYPE i.
      DATA lv_detailed TYPE abap_bool.
      DATA lt_classes TYPE string_table.
      CLEAR lt_classes.
      lv_selector = ls_profile-selvar.
      lv_selector_value = lv_selector.
      lv_detailed = xsdbool( lv_selector_value = 1 OR lines( message_ids( lv_vector ) ) > 0 ).
      IF lv_detailed = abap_false.
        lt_classes = class_names( ls_profile-classes ).
      ENDIF.
      append_lines(
        EXPORTING
          iv_source   = 'Static'
          iv_profile  = ls_profile-profname
          iv_slot     = ls_profile-slotno
          iv_client   = ls_profile-client
          iv_user     = ls_profile-uname
          iv_status   = ls_profile-status
          iv_vector   = lv_vector
          iv_detailed = lv_detailed
          it_classes  = lt_classes
        CHANGING
          ct_rows     = rt_rows ).
    ENDLOOP.
  ENDMETHOD.

  METHOD dynamic_rows.
    DATA lt_slot TYPE STANDARD TABLE OF rsauinfo.
    CALL FUNCTION 'RSAU_GET_AUDIT_CONFIG'
      TABLES
        slotinfo         = lt_slot
      EXCEPTIONS
        no_authority     = 1
        shm_access_error = 2
        OTHERS           = 3.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    DATA lv_host TYPE c LENGTH 32.
    lv_host = sy-host.
    LOOP AT lt_slot INTO DATA(ls_slot).
      DATA lt_classes TYPE string_table.
      CLEAR lt_classes.
      IF ls_slot-login = 'X'.
        APPEND 'Logon' TO lt_classes.
      ENDIF.
      IF ls_slot-rfclogin = 'X'.
        APPEND 'RFC logon' TO lt_classes.
      ENDIF.
      IF ls_slot-tastart = 'X'.
        APPEND 'Transaction start' TO lt_classes.
      ENDIF.
      IF ls_slot-repostart = 'X'.
        APPEND 'Report' TO lt_classes.
      ENDIF.
      IF ls_slot-userstamm = 'X'.
        APPEND 'User master' TO lt_classes.
      ENDIF.
      IF ls_slot-rfcstart = 'X'.
        APPEND 'RFC call' TO lt_classes.
      ENDIF.
      IF ls_slot-sonst = 'X'.
        APPEND 'Other' TO lt_classes.
      ENDIF.
      IF ls_slot-system = 'X'.
        APPEND 'System' TO lt_classes.
      ENDIF.

      DATA lv_vector TYPE xstring.
      CLEAR lv_vector.
      lv_vector = ls_slot-msgvect.
      DATA lv_selector TYPE x LENGTH 1.
      DATA lv_selector_value TYPE i.
      lv_selector = ls_slot-selvar.
      lv_selector_value = lv_selector.
      DATA(lv_has_events) = xsdbool( lines( message_ids( lv_vector ) ) > 0 ).
      IF lv_selector_value <> 1 AND lv_has_events = abap_false AND lt_classes IS INITIAL
          AND ls_slot-uname IS INITIAL AND ls_slot-mandt IS INITIAL AND ls_slot-status IS INITIAL.
        CONTINUE.
      ENDIF.

      append_lines(
        EXPORTING
          iv_source   = 'Dynamic'
          iv_host     = lv_host
          iv_slot     = sy-tabix
          iv_client   = ls_slot-mandt
          iv_user     = ls_slot-uname
          iv_status   = ls_slot-status
          iv_vector   = lv_vector
          iv_detailed = xsdbool( lv_selector_value = 1 OR lv_has_events = abap_true )
          it_classes  = lt_classes
        CHANGING
          ct_rows     = rt_rows ).
    ENDLOOP.
  ENDMETHOD.

  METHOD read_rows.
    mo_auth->check_audit_display( ).
    IF io_request IS NOT BOUND.
      RETURN.
    ENDIF.
    rt_rows = static_rows( ).
    APPEND LINES OF dynamic_rows( ) TO rt_rows.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    DATA(lt_rows) = read_rows( io_request ).
    zcl_sec_query_util=>apply_access(
      EXPORTING io_request = io_request io_response = io_response
      CHANGING ct_rows = lt_rows ).
  ENDMETHOD.
ENDCLASS.
