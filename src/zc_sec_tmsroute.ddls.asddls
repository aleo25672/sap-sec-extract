@EndUserText.label: 'Transport route'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_TMSROUTE_QUERY'
define custom entity ZC_SEC_TMSROUTE
{
  key RouteKind            : abap.char(15);
  key ConfigVersion        : abap.numc(4);
  key TransportLayer       : abap.char(4);
  key SourceSystem         : abap.char(10);
  key TargetSystem         : abap.char(10);
  key ConsolidationSystem  : abap.char(10);
}
