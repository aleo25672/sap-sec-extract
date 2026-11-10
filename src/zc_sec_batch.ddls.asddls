@EndUserText.label: 'Batch input session'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_BATCH_QUERY'
define custom entity ZC_SEC_BATCH
{
  key Client             : abap.char(3);
  key QueueId            : abap.char(20);
      SessionName        : abap.char(12);
      Creator            : abap.char(12);
      CreatedOn          : abap.dats;
      CreatedAt          : abap.tims;
      QueueState         : abap.char(1);
      QueueStateText     : abap.char(40);
      TransactionCount   : abap.int4;
      ErrorCount         : abap.int4;
      DeletedCount       : abap.int4;
      StartedOn          : abap.char(10);
      StartedAt          : abap.char(8);
      UserName           : abap.char(12);
}
