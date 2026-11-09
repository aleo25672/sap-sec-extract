@EndUserText.label: 'Company code'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_COMPANY_QUERY'
define custom entity ZC_SEC_COMPANY
{
  key CompanyCode        : abap.char(4);
      CompanyName        : abap.char(25);
      Country            : abap.char(3);
      Currency           : abap.char(5);
      ChartOfAccounts    : abap.char(4);
      FiscalYearVariant  : abap.char(2);
      Productive         : abap.char(1);
      Language           : abap.char(1);
}
