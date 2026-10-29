INTERFACE zif_sec_tcode_usage_source
  PUBLIC.

  TYPES:
    tt_date TYPE STANDARD TABLE OF dats WITH EMPTY KEY,
    BEGIN OF ty_usage,
      userid                 TYPE swncuname,
      entryid                TYPE swncentryid,
      tasktype               TYPE swnctasktyperaw,
      periodtype             TYPE swncperitype,
      periodstart            TYPE swncdatum,
      stepcount              TYPE swnccntagg,
      dialogstepcount        TYPE swnccntagg,
      transactioncallcount   TYPE swnccntagg,
    END OF ty_usage,
    tt_usage TYPE STANDARD TABLE OF ty_usage WITH EMPTY KEY.

  METHODS read_transaction_usage
    IMPORTING
      iv_periodtype   TYPE csequence
      it_periodstart  TYPE tt_date
      it_userid       TYPE zcl_sec_query_util=>tt_range
    RETURNING
      VALUE(rt_rows)  TYPE tt_usage
    RAISING
      zcx_sec_access.
ENDINTERFACE.
