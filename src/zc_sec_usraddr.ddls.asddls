@EndUserText.label: 'User address'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_USRADDR_QUERY'
define custom entity ZC_SEC_USRADDR
{
  key UserName        : abap.char(12);
      Client          : abap.char(3);
      FirstName       : abap.char(40);
      LastName        : abap.char(40);
      FullName        : abap.char(80);
      EmailAddress    : abap.char(241);
      Department      : abap.char(40);
      PhoneExtension  : abap.char(10);
      Building        : abap.char(10);
      Room            : abap.char(10);
      InternalMail    : abap.char(10);
      CostCenter      : abap.char(8);
      CompanyName     : abap.char(40);
      City            : abap.char(40);
      PostalCode      : abap.char(10);
      Company         : abap.char(42);
}
