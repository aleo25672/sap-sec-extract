@AbapCatalog.sqlViewName: 'ZISEC_ROLE_CHG'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Security access role change'
define view ZI_SEC_ROLE_CHG
  as select from cdhdr
  left outer join cdpos on cdpos.objectclas = cdhdr.objectclas
                       and cdpos.objectid   = cdhdr.objectid
                       and cdpos.changenr   = cdhdr.changenr
{
  key cdhdr.objectid                                              as RoleName,
  key cdhdr.changenr                                              as ChangeNumber,
      coalesce( cdpos.tabname, cast( '' as abap.char(30) ) )      as TableName,
      coalesce( cdpos.tabkey, cast( '' as abap.char(70) ) )       as TableKey,
      coalesce( cdpos.fname, cast( '' as abap.char(30) ) )        as FieldName,
      coalesce( cdpos.chngind, cast( '' as abap.char(1) ) )       as ItemChange,
      cdhdr.username                                              as ChangedBy,
      cdhdr.udate                                                 as ChangeDate,
      cdhdr.utime                                                 as ChangeTime,
      cdhdr.tcode                                                 as TransactionCode,
      cdhdr.change_ind                                            as HeaderChange,
      // Same tables and fields as ZCL_SEC_USR_CHG_GUARD and ZI_SEC_USR_CHG.
      cast(
        case
          when cdpos.tabname is initial
            or cdpos.tabname = 'ADRP' or cdpos.tabname = 'ADRC' or cdpos.tabname = 'ADR2'
            or cdpos.tabname = 'ADR3' or cdpos.tabname = 'ADR6' or cdpos.tabname = 'ADCP'
            or cdpos.tabname = 'ADRT' or cdpos.tabname = 'USR03'
            or cdpos.fname = 'BCODE' or cdpos.fname = 'PASSCODE' or cdpos.fname = 'PWDSALTEDHASH'
            or cdpos.fname = 'PASSWORD'
            or cdpos.fname = 'OCOD1' or cdpos.fname = 'OCOD2' or cdpos.fname = 'OCOD3'
            or cdpos.fname = 'OCOD4' or cdpos.fname = 'OCOD5'
            or cdpos.fname = 'NAME_FIRST' or cdpos.fname = 'NAME_LAST' or cdpos.fname = 'NAME_TEXT'
            or cdpos.fname = 'NAME_LAST2' or cdpos.fname = 'NICKNAME'
            or cdpos.fname = 'MC_NAMEFIR' or cdpos.fname = 'MC_NAMELAS'
            or cdpos.fname = 'NAME1' or cdpos.fname = 'NAME2' or cdpos.fname = 'NAME3' or cdpos.fname = 'NAME4'
            or cdpos.fname = 'SMTP_ADDR' or cdpos.fname = 'SMTP_SRCH' or cdpos.fname = 'INTAD'
            or cdpos.fname = 'FIRSTNAME' or cdpos.fname = 'LASTNAME'
            or cdpos.fname = 'TEL_NUMBER' or cdpos.fname = 'TELNR' or cdpos.fname = 'TELNR_LONG'
            or cdpos.fname = 'TEL_EXTENS' or cdpos.fname = 'MOB_NUMBER'
            then cast( '' as abap.char(254) )
          else cdpos.value_old
        end as abap.char(254) )                                   as ValueOld,
      cast(
        case
          when cdpos.tabname is initial
            or cdpos.tabname = 'ADRP' or cdpos.tabname = 'ADRC' or cdpos.tabname = 'ADR2'
            or cdpos.tabname = 'ADR3' or cdpos.tabname = 'ADR6' or cdpos.tabname = 'ADCP'
            or cdpos.tabname = 'ADRT' or cdpos.tabname = 'USR03'
            or cdpos.fname = 'BCODE' or cdpos.fname = 'PASSCODE' or cdpos.fname = 'PWDSALTEDHASH'
            or cdpos.fname = 'PASSWORD'
            or cdpos.fname = 'OCOD1' or cdpos.fname = 'OCOD2' or cdpos.fname = 'OCOD3'
            or cdpos.fname = 'OCOD4' or cdpos.fname = 'OCOD5'
            or cdpos.fname = 'NAME_FIRST' or cdpos.fname = 'NAME_LAST' or cdpos.fname = 'NAME_TEXT'
            or cdpos.fname = 'NAME_LAST2' or cdpos.fname = 'NICKNAME'
            or cdpos.fname = 'MC_NAMEFIR' or cdpos.fname = 'MC_NAMELAS'
            or cdpos.fname = 'NAME1' or cdpos.fname = 'NAME2' or cdpos.fname = 'NAME3' or cdpos.fname = 'NAME4'
            or cdpos.fname = 'SMTP_ADDR' or cdpos.fname = 'SMTP_SRCH' or cdpos.fname = 'INTAD'
            or cdpos.fname = 'FIRSTNAME' or cdpos.fname = 'LASTNAME'
            or cdpos.fname = 'TEL_NUMBER' or cdpos.fname = 'TELNR' or cdpos.fname = 'TELNR_LONG'
            or cdpos.fname = 'TEL_EXTENS' or cdpos.fname = 'MOB_NUMBER'
            then cast( '' as abap.char(254) )
          else cdpos.value_new
        end as abap.char(254) )                                   as ValueNew
}
where cdhdr.objectclas = 'PFCG'
