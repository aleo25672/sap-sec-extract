CLASS zcl_sec_salcfg_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        profilename    TYPE c LENGTH 8,
        slotnumber     TYPE n LENGTH 4,
        activeprofile  TYPE c LENGTH 8,
        auditclasses   TYPE i,
        auditclasstext TYPE c LENGTH 120,
        severity       TYPE i,
        severitytext   TYPE c LENGTH 10,
        client         TYPE c LENGTH 3,
        username       TYPE c LENGTH 12,
        slotstatus     TYPE c LENGTH 1,
        changedby      TYPE c LENGTH 12,
        changedon      TYPE d,
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

    METHODS class_text
      IMPORTING
        iv_classes     TYPE i
      RETURNING
        VALUE(rv_text) TYPE string.

    METHODS severity_text
      IMPORTING
        iv_severity    TYPE i
      RETURNING
        VALUE(rv_text) TYPE string.
ENDCLASS.


CLASS zcl_sec_salcfg_query IMPLEMENTATION.
  METHOD constructor.
    mo_auth = io_auth.
    IF mo_auth IS NOT BOUND.
      mo_auth = NEW zcl_sec_access_auth( ).
    ENDIF.
  ENDMETHOD.

  METHOD class_text.
    DATA lv_bit TYPE i VALUE 1.
    DATA lv_name TYPE string.
    WHILE lv_bit <= 128.
      IF ( iv_classes DIV lv_bit ) MOD 2 = 1.
        CASE lv_bit.
          WHEN 1.
            lv_name = 'Other'.
          WHEN 2.
            lv_name = 'Logon'.
          WHEN 4.
            lv_name = 'Transaction start'.
          WHEN 8.
            lv_name = 'Report'.
          WHEN 16.
            lv_name = 'RFC logon'.
          WHEN 32.
            lv_name = 'User master'.
          WHEN 64.
            lv_name = 'System'.
          WHEN 128.
            lv_name = 'RFC call'.
        ENDCASE.
        IF rv_text IS INITIAL.
          rv_text = lv_name.
        ELSE.
          rv_text = rv_text && `, ` && lv_name.
        ENDIF.
      ENDIF.
      lv_bit = lv_bit * 2.
    ENDWHILE.
  ENDMETHOD.

  METHOD severity_text.
    CASE iv_severity.
      WHEN 0.
        rv_text = ''.
      WHEN 2.
        rv_text = 'Low'.
      WHEN 5.
        rv_text = 'Medium'.
      WHEN 9.
        rv_text = 'High'.
      WHEN OTHERS.
        rv_text = iv_severity.
    ENDCASE.
  ENDMETHOD.

  METHOD read_rows.
    mo_auth->check_audit_display( ).
    IF io_request IS NOT BOUND.
      RETURN.
    ENDIF.

    " RSAUPROF is the static SM19 profile. The event bit vector in MSGVECT stays in the table.
    SELECT profname, slotno, currprof, classes, severity, client, uname, status, cuname, cdate
      FROM rsauprof
      INTO TABLE @DATA(lt_profile).

    LOOP AT lt_profile INTO DATA(ls_profile).
      DATA(lv_classes) = ``.
      DATA(lv_severity) = ``.
      IF ls_profile-profname <> '$KERNEL$' AND ls_profile-profname <> '$CURPROF$'
          AND ls_profile-slotno > 0.
        IF ls_profile-classes = 0 AND ls_profile-severity = 0.
          lv_classes = 'Detailed events'.
        ELSE.
          lv_classes = class_text( ls_profile-classes ).
          lv_severity = severity_text( ls_profile-severity ).
        ENDIF.
      ENDIF.
      APPEND VALUE ty_row(
        profilename    = ls_profile-profname
        slotnumber     = ls_profile-slotno
        activeprofile  = ls_profile-currprof
        auditclasses   = ls_profile-classes
        auditclasstext = lv_classes
        severity       = ls_profile-severity
        severitytext   = lv_severity
        client         = ls_profile-client
        username       = ls_profile-uname
        slotstatus     = ls_profile-status
        changedby      = ls_profile-cuname
        changedon      = ls_profile-cdate ) TO rt_rows.
    ENDLOOP.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    DATA(lt_rows) = read_rows( io_request ).
    zcl_sec_query_util=>apply_access(
      EXPORTING io_request = io_request io_response = io_response
      CHANGING ct_rows = lt_rows ).
  ENDMETHOD.
ENDCLASS.
