@EndUserText.label: 'SE16N change document'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_SE16N_QUERY'
define custom entity ZC_SEC_SE16N
{
  key DocumentId        : abap.dec(21,7);
      Client            : abap.char(3);
      TableName         : abap.char(30);
      UserName          : abap.char(12);
      ChangedOn         : abap.dats;
      ChangedAt         : abap.tims;
      ClientDependent   : abap.char(1);
}
