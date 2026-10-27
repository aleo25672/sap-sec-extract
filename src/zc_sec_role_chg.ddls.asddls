@EndUserText.label: 'Security access role change'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_ROLE_CHG_QUERY'
define custom entity ZC_SEC_ROLE_CHG
{
  key RoleName        : abap.char(90);
  key ChangeNumber    : abap.char(10);
  key TableName       : abap.char(30);
  key TableKey        : abap.char(70);
  key FieldName       : abap.char(30);
  key ItemChange      : abap.char(1);
      Client          : abap.char(3);
      ChangedBy       : abap.char(12);
      ChangeDate      : abap.dats;
      ChangeTime      : abap.tims;
      TransactionCode : abap.char(20);
      HeaderChange    : abap.char(1);
      ValueOld        : abap.char(254);
      ValueNew        : abap.char(254);
}
