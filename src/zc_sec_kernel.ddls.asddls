@EndUserText.label: 'Kernel information'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_KERNEL_QUERY'
define custom entity ZC_SEC_KERNEL
{
  key SystemId           : abap.char(8);
  key ApplicationServer  : abap.char(32);
      KernelRelease      : abap.string(0);
      KernelPatchLevel   : abap.string(0);
      CompiledOn         : abap.string(0);
      CompiledAt         : abap.string(0);
      DatabaseLibrary    : abap.string(0);
}
