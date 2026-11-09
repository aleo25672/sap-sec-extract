@EndUserText.label: 'Program catalog'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_PROGRAM_QUERY'
define custom entity ZC_SEC_PROGRAM
{
  key ProgramName          : abap.char(40);
      ProgramType          : abap.char(1);
      ProgramTypeText      : abap.char(60);
      CreatedBy            : abap.char(12);
      CreatedOn            : abap.dats;
      ChangedBy            : abap.char(12);
      ChangedOn            : abap.dats;
      Version              : abap.char(10);
      AuthorizationGroup   : abap.char(8);
      UnicodeCheck         : abap.char(1);
}
