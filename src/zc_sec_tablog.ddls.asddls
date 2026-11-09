@EndUserText.label: 'Table logging flag'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_TABLOG_QUERY'
define custom entity ZC_SEC_TABLOG
{
  key TableName        : abap.char(30);
      LogDataChanges   : abap.char(1);
}
