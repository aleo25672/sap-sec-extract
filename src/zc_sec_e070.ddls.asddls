@EndUserText.label: 'Transport request'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_E070_QUERY'
define custom entity ZC_SEC_E070
{
  key Request             : abap.char(20);
      RequestFunction     : abap.char(1);
      RequestFunctionText : abap.char(60);
      RequestStatus       : abap.char(1);
      RequestStatusText   : abap.char(40);
      TargetSystem        : abap.char(10);
      Category            : abap.char(4);
      CategoryText        : abap.char(20);
      Owner               : abap.char(12);
      ChangedOn           : abap.dats;
      ChangedAt           : abap.tims;
      ParentRequest       : abap.char(20);
      Description         : abap.char(60);
}
