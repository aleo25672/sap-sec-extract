@EndUserText.label: 'Security access transaction usage'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_TCODE_USAGE_QUERY'
define custom entity ZC_SEC_TCODE_USAGE
{
  key UserId                 : abap.char(12);
  key EntryId                : abap.char(73);
  key TaskType               : abap.char(2);
  key PeriodType             : abap.char(1);
  key PeriodStart            : abap.dats;
      Client                 : abap.char(3);
      StepCount              : abap.dec(24,0);
      DialogStepCount        : abap.dec(24,0);
      TransactionCallCount   : abap.dec(24,0);
}
