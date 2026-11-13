# Control guide

Each control below is one row of the PBC list. The two services return stored rows. They do not decide whether a result passes. That decision is the logic in the control.

Every control has four parts:

1. **Purpose.** What the review is trying to conclude.
2. **Data.** The entity sets that hold the raw rows. Replace sample dates with the fiscal year under review. Follow `@odata.nextLink` until it is absent. In a browser, write each space in `$filter` as `%20`.
3. **Fields.** What each field means, in plain language.
4. **Logic.** How the rows are combined, and which rows answer the control.

The spreadsheet uses F.66 twice and has no F.44 or F.60. Both F.66 rows are kept, under the table each one exports.

## How a stored value matches

`Low` and `High` are the range stored on one authorization field. A tested value matches when it is inside that range, including the endpoints. `Low` `*` matches every value. A blank `High` means the range is the single value in `Low`.

Several fields of one authorization belong together only when they share the same authorization. On a role, that is the same `RoleName` and the same `Counter`. On a profile, that is the same `Object`, `AuthName`, and `Version` `A`. An `AND` across two authorization objects is two authorizations on the same role or the same profile, not two fields of one authorization.

Activity values used below: `01` create, `02` change, `03` display, `07` activate, `12` maintain, `22` assign.

## How a user receives access

A user has a role when `RoleAssignments` has that `UserId` and `RoleName`, `ValidFrom` is on or before the review date, `ValidTo` is on or after it, and `Excluded` is blank. `FromCompositeRole` `X` means the single role arrived through a composite. `RoleHierarchy` names that composite in `CompositeRole` and the single role in `SingleRole`. `FromOrgManagement` `X` means organizational management assigned the role.

A user has a profile when `ProfileAssignments` has that `UserId` and `ProfileName`. `ProfileSource` `Assigned` is stored on the user. `ProfileSource` `ReferenceUser` is a profile of `Users.ReferenceUser`. The reference user's roles are not copied onto the dialog user.

`RoleProfiles` with `Version` `A` is the profile generated from a single role. A profile on the user that finds no active `RoleProfiles` row was not generated from a role that still exists. `SAP_ALL` in `ProfileAssignments` is full access by itself.

Controls F.27 to F.39 and F.50 to F.56 use this join. Each of those controls states the extra rule that selects the role or the profile.

## F.1 System status

**Purpose.** Identifies the system that produced the evidence: release, database, and installation number. Later samples are tied back to this system.

**Data.** `SystemStatus` on `ZAPI_SEC_SETTINGS`. One row for the application server that answered.

**Fields.**

| Field | Meaning |
| --- | --- |
| SystemId | SAP system id, for example `S4H`. |
| ApplicationServer | Server that answered this call. |
| DatabaseSystem | Database platform. |
| DatabaseHost | Host of the database. |
| DatabaseRelease | Database version. |
| OperatingSystem | Operating system of the application server. |
| MachineType | Hardware type reported by the kernel. |
| IpAddress | IP address of the application server. |
| SapRelease | Basis release. |
| UnicodeSystem | Whether the system is Unicode. |
| InstallationNumber | License installation number. |

**Logic.** No join. The row is the system identity for every other control taken from this server.

## F.2 Kernel information

**Purpose.** Shows the kernel release and patch of the application server that answered.

**Data.** `KernelInformation` on `ZAPI_SEC_SETTINGS`.

**Fields.**

| Field | Meaning |
| --- | --- |
| SystemId | SAP system id. |
| ApplicationServer | Server that answered. |
| KernelRelease | Kernel release. |
| KernelPatchLevel | Kernel patch. |
| CompiledOn | Date the kernel was compiled. |
| CompiledAt | Time the kernel was compiled. |
| DatabaseLibrary | Database client library linked into the kernel. |

**Logic.** No join. Read it together with F.1 when the review names both the basis release and the kernel.

## F.3 Software components

**Purpose.** Lists the installed software components and their support package levels.

**Data.** `SoftwareComponents` on `ZAPI_SEC_SETTINGS`, from `CVERS`.

**Fields.**

| Field | Meaning |
| --- | --- |
| Component | Software component name. |
| ComponentRelease | Release of that component (`CVERS-RELEASE`). |
| SupportPackageLevel | Support package level (`CVERS-EXTRELEASE`). |
| ComponentType | Kind of component. |
| ComponentTypeText | Plain-language name of that kind. |

**Logic.** No join. One row is one installed component.

## F.4 Transport domain

**Purpose.** Shows the transport domain and the systems in it, including the domain controller.

**Data.** `TransportDomains` and `TransportSystems` on `ZAPI_SEC_SETTINGS`.

**Fields.**

| Field | Meaning |
| --- | --- |
| DomainName | Transport domain. |
| ControllerSystem | System that controls the domain (`DOMCTL`). |
| Description | Description stored for the domain or the system. |
| SystemName | One system in the domain. |
| SystemType | `S` SAP system, `V` virtual, `E` external. |
| SystemTypeText | Plain-language name of that type. |
| TransportGroup | Transport group the system belongs to. |

**Logic.** Join `TransportSystems.DomainName` to `TransportDomains.DomainName`. The controller is the system named in `ControllerSystem`.

## F.5 Transport routes

**Purpose.** Shows the path a change is meant to follow from one system to the next.

**Data.** `TransportRoutes` on `ZAPI_SEC_SETTINGS`. Consolidation routes come from `TCERELE` and delivery routes from `TCEDELI`, for the newest configuration version.

**Fields.**

| Field | Meaning |
| --- | --- |
| RouteKind | `Consolidation` or `Delivery`. |
| ConfigVersion | Transport configuration version. Keep the newest. |
| TransportLayer | Transport layer of a consolidation route. |
| SourceSystem | System the route leaves. |
| TargetSystem | System the route enters. |
| ConsolidationSystem | Consolidation system named on the route. |

**Logic.** No join to another set. Read `SourceSystem` to `TargetSystem` for each `RouteKind`. A consolidation row uses `INTSYS` as the source and `CONSYS` as the target. A delivery row uses `FROMSYSTEM` and `TOSYSTEM`.

## F.6 Import history

**Purpose.** Lists transports imported during the fiscal year and whether each import succeeded.

**Data.** `ImportHistory` on `ZAPI_SEC_SETTINGS`, from `TPALOG`. `ImportOn` needs a start and an end.

**Fields.**

| Field | Meaning |
| --- | --- |
| ImportTimestamp | Full timestamp of the import step. |
| ImportOn | Date of that timestamp. This is the period filter. |
| Request | Transport request. |
| TargetSystem | System that received the import. |
| SourceClient | Client the request was exported from. |
| Step | Import step. |
| AllClients | Whether the import applied to all clients. |
| Project | CTS project, when one is stored. |
| UserName | User who started the import. |
| ReturnCode | `0000` success, `0004` warning, `0008` error. |
| ReturnCodeText | Plain-language result. |
| HostName | Host that performed the import. |
| Administrator | Transport administrator stored on the step. |

**Logic.** Filter `ImportOn` to the fiscal year. A request can have several steps. The review looks at `ReturnCode` per step. This is the import log, not the list of requests changed in this system (F.58).

## F.7 rec/client

**Purpose.** Shows which clients are allowed to receive transports. A productive client in that list can be imported into directly.

**Data.** `SecurityProfileParameters` on `ZAPI_SEC_SETTINGS`, filtered to `ParameterName` `rec/client`. The STMS transport-tool screen is not a separate set.

**Fields.**

| Field | Meaning |
| --- | --- |
| ParameterName | `rec/client` for this control. |
| InstanceProfileValue | Value set in the instance profile. This is the value in force when it is filled. |
| KernelDefaultValue | Value used when the instance profile does not set one. |
| Description | Parameter description. |
| SecurityRelevant | Whether the parameter is classified as security-relevant. |
| SecurityArea | Security area of the parameter. |
| ApplicationServer | Server the value was read from. |

**Logic.** No join. Use `InstanceProfileValue` when it is filled, otherwise `KernelDefaultValue`. The value is a list of client numbers, or `ALL`.

## F.8 Batch input sessions

**Purpose.** Finds batch-input sessions that have not finished. An open or failed session can still post, or can show that a posting did not complete.

**Data.** `BatchInputSessions` on `ZAPI_SEC_SETTINGS`. Keep rows whose `QueueState` is not `F`.

**Fields.**

| Field | Meaning |
| --- | --- |
| QueueId | Session queue id. |
| SessionName | Name shown in SM35. |
| Creator | User who created the session. |
| CreatedOn, CreatedAt | When it was created. |
| QueueState | Blank to be processed, `C` creating, `E` incorrect, `F` finished, `R` processing, `S` in background. |
| QueueStateText | Plain-language state. |
| TransactionCount | Transactions in the session. |
| ErrorCount | Transactions in error. |
| DeletedCount | Transactions deleted from the session. |
| StartedOn, StartedAt | When processing started. Blank when it has not started. |
| UserName | User the session runs as. |

**Logic.** No join. A row with `QueueState` other than `F` is not finished. The session password is not returned.

## F.9 Security policy attributes

**Purpose.** Shows the password and logon rules in force on each security policy.

**Data.** `SecurityPolicyAttributes` on `ZAPI_SEC_SETTINGS`. This includes values stored in `SEC_POLICY_RT`.

**Fields.**

| Field | Meaning |
| --- | --- |
| PolicyName | Security policy. |
| AttributeName | One rule, such as a password length or a lock threshold. |
| EffectiveValue | Value in force. |
| DefaultValue | SAP default for that attribute. |
| ValueOrigin | Whether the effective value is stored on the policy or taken from the default. |
| ProfileParameter | Profile parameter this attribute supersedes, when one exists. |
| Description | Description of the attribute. |

**Logic.** Join `PolicyName` to F.10. Join `ProfileParameter` to `SecurityProfileParameters.ParameterName` (F.41) when the review compares the policy with the profile. `Users.SecurityPolicy` names the policy that applies to an account.

## F.10 Security policies

**Purpose.** Lists the security policies defined in the client, and how many users are counted on each.

**Data.** `SecurityPolicies` on `ZAPI_SEC_SETTINGS`, from `SEC_POLICY_CUST`.

**Fields.**

| Field | Meaning |
| --- | --- |
| PolicyName | Policy name. Join to F.9. |
| Description | Text of the policy. |
| CreatedBy, CreatedOn | Who created it, and when. |
| ChangedBy, ChangedOn | Who last changed it, and when. |
| AssignedUserCount | Users in this client counted on the policy. |
| UsersCounted | Whether the count was taken. |

**Logic.** One policy has many attributes in F.9. The user ids are not in this set. They are `Users.SecurityPolicy`.

## F.11 Client settings

**Purpose.** Shows the SCC4 settings: client role, whether changes are allowed, and whether the client is locked. A production client is expected to be closed for changes.

**Data.** `ClientSettings` on `ZAPI_SEC_SETTINGS`, from `T000`.

**Fields.**

| Field | Meaning |
| --- | --- |
| Client | Client number. |
| ClientName | Client description. |
| ClientRole | Client role, such as production or customizing. |
| ClientRoleText | Plain-language role. |
| ClientSpecificChanges | Whether changes inside this client are allowed. |
| CrossClientChanges | Whether cross-client changes are allowed. |
| ClientCopyProtection | Protection against client copy. |
| CattAllowed | Whether CATT is allowed. |
| UpgradeCascadeLocked | Whether the upgrade cascade is locked. |
| TemporarilyLocked | Whether the client is locked against logon. |
| LogicalSystem | Logical system name. |
| LastChangedBy, LastChangedOn | Last change of these settings. |
| TableChangeLogging | Client-level table logging switch. |

**Logic.** No join for the current settings. F.40 is the history of changes to this table. F.12 says which company codes in the logon client are productive.

## F.12 Company codes

**Purpose.** Separates productive company codes from test company codes.

**Data.** `CompanyCodes` on `ZAPI_SEC_SETTINGS`, from `T001` in the logon client.

**Fields.**

| Field | Meaning |
| --- | --- |
| CompanyCode | Company code. |
| CompanyName | Name. |
| Country | Country. |
| Currency | Local currency. |
| ChartOfAccounts | Chart of accounts. |
| FiscalYearVariant | Fiscal year variant. |
| Productive | `XPROD`. Filled when the company code is marked productive. |
| Language | Language. |

**Logic.** No join. `Productive` is the field the guidance asks to show.

## F.13 Logon data

**Purpose.** The user population for the access review: type, lock, validity, and last logon. The password hash is not exported.

**Data.** `Users` on `ZAPI_SEC_ACCESS`, from `USR02`.

**Fields.**

| Field | Meaning |
| --- | --- |
| UserId | User name. |
| UserType | `A` dialog, `B` system, `C` communication, `S` service, `L` reference. |
| UserTypeText | Plain-language type. |
| UserGroup | User group. |
| ValidFrom, ValidTo | Validity of the account. |
| GloballyLocked | Locked by the administrator. |
| LocallyLocked | Locked in this client. |
| FailedLogonLocked | Locked after failed logons. |
| PasswordState | Whether a password is set, initial, or deactivated. |
| PasswordStateText | Plain-language password state. |
| PasswordHashVersion | Hash algorithm version. The hash itself is not returned. |
| LastLogonDate, LastLogonTime | Last successful logon. |
| CreatedBy, CreatedOn | Who created the account, and when. |
| SecurityPolicy | Policy from F.10 that applies to this user. |
| ReferenceUser | Reference user whose profiles are added. See F.17. |

**Logic.** One row is one user in the logon client. Other controls join `UserId` here.

## F.14 User addresses

**Purpose.** Ties a user id to a person, using the name and email stored on the account.

**Data.** `UserAddresses` on `ZAPI_SEC_ACCESS`, from `USER_ADDR` and `ADR6`.

**Fields.**

| Field | Meaning |
| --- | --- |
| UserName | User id. Join to `Users.UserId`. |
| FullName | Display name (`NAME_TEXTC`). |
| FirstName, LastName | Name parts. |
| EmailAddress | Standard email (`SMTP_ADDR`). |
| Department, PhoneExtension, Building, Room | Address details. |
| CompanyName, City, PostalCode, Company | Company address stored on the user. |
| CostCenter, InternalMail | Organizational details. |

**Logic.** Join `UserName` to `Users.UserId`. A user with no address row has no name or email in this export.

## F.15 Table logging flag

**Purpose.** Shows whether each table writes a change log. A table with logging off has no table change log.

**Data.** `TableLogging` on `ZAPI_SEC_SETTINGS`, from `DD09L`.

**Fields.**

| Field | Meaning |
| --- | --- |
| TableName | Table. |
| LogDataChanges | `PROTOKOLL`. Filled when logging is on. |

**Logic.** No join. Use `TableName` `T000` when the review asks whether client-setting changes can be logged. F.40 is the log itself, and it is empty when logging was off.

## F.16 Profile parameter changes

**Purpose.** Shows the profile parameter values recorded over time, so a change during the fiscal year can be seen against the current value.

**Data.** `ProfileParameterChanges` on `ZAPI_SEC_SETTINGS`, from `PAHI`. Filter `ChangeDate` from the first day of the fiscal year, or omit the filter for the whole table.

**Fields.**

| Field | Meaning |
| --- | --- |
| ParameterName | Parameter that changed. |
| ChangeDate | Date of the change. |
| ParameterValue | Value recorded on that change. |
| ParameterState | State code from `PAHI`. `ParameterStateText` is its description. |
| ParameterType | Kind of parameter record. |
| SecurityRelevant | Whether the parameter is security-relevant. |
| SecurityArea | Security area. |
| HostName, SystemId | Where the change was recorded. |

**Logic.** Sort by `ParameterName` and `ChangeDate`. Each row is the value recorded on that date. The current value is F.41. The row has no time and no user.

## F.17 Reference user

**Purpose.** Shows accounts that inherit profiles from a reference user, so their access is wider than their own roles.

**Data.** `Users` and `ProfileAssignments` with `ProfileSource` `ReferenceUser`.

**Fields.** `Users.ReferenceUser` is the reference user. `ProfileAssignments.UserId` is the account, `ProfileName` is an inherited profile, and `ReferenceUser` repeats the source account.

**Logic.** For each user whose `ReferenceUser` is filled, the profiles with `ProfileSource` `ReferenceUser` are added to that user. The reference user's role assignments are not added.

## F.18 Profiles on the user

**Purpose.** Lists profiles assigned directly to each user, including profiles that were not generated from a role.

**Data.** `ProfileAssignments` with `ProfileSource` `Assigned`, from `UST04`.

**Fields.**

| Field | Meaning |
| --- | --- |
| UserId | User. |
| ProfileName | Profile stored on the user. |
| ProfileSource | `Assigned` for this control. |

**Logic.** Join `ProfileName` to `RoleProfiles.ProfileName` where `Version` is `A`. A profile that finds a row was generated by that `RoleName`. A profile that finds none, including `SAP_ALL`, was not generated from a current role.

## F.19 SE16N changes

**Purpose.** Lists edits made through SE16N. A direct table edit bypasses the transaction that normally maintains that data.

**Data.** `Se16nChangeDocuments` on `ZAPI_SEC_SETTINGS`, from `SE16N_CD_KEY`. Filter `ChangedOn` to the fiscal year, or `TableName` when the review names a table.

**Fields.**

| Field | Meaning |
| --- | --- |
| DocumentId | Change document id. |
| TableName | Table that was edited. |
| UserName | User who edited it. |
| ChangedOn, ChangedAt | When. |
| ClientDependent | Whether the edited table is client-dependent. |

**Logic.** No join. The old and new field values are not in the row. The row is the fact that SE16N changed the table.

## F.20 PFCG customizing

**Purpose.** Shows the PFCG switches. `CHECK_S_USER_SAS` is the switch that restricts assignment of sensitive roles.

**Data.** `RoleCustomizing` on `ZAPI_SEC_SETTINGS`, from `PRGN_CUST`.

**Fields.**

| Field | Meaning |
| --- | --- |
| CustomizingId | Switch name (`ID`). |
| CustomizingValue | Stored value. |

**Logic.** Read the row `CustomizingId` `CHECK_S_USER_SAS`. The review interprets the stored value. A missing row means the switch is not set.

## F.21 Forbidden passwords

**Purpose.** Lists password patterns users are not allowed to choose. It complements the policy rules in F.9.

**Data.** `ForbiddenPasswords` on `ZAPI_SEC_SETTINGS`, from `USR40`.

**Fields.**

| Field | Meaning |
| --- | --- |
| PasswordPattern | Forbidden pattern. This is not a user's password. |
| CaseSensitive | Whether the pattern is case-sensitive. |

**Logic.** No join. The list is the whole control.

## F.22 Developer keys

**Purpose.** Lists users who hold a developer key and can change repository objects. The key value is not exported.

**Data.** `DeveloperKeys` on `ZAPI_SEC_ACCESS`, from `DEVACCESS`.

**Fields.** `UserName` is the user who holds a key. The table is client-independent, so the row is for this system.

**Logic.** Join `UserName` to `Users.UserId` to see the account type and lock. The key itself is not in the row.

## F.23 Role changes

**Purpose.** History of role changes during the fiscal year: who changed which role, and which field changed.

**Data.** `RoleChangeDocuments` on `ZAPI_SEC_ACCESS`. Filter `ChangeDate` from the first day of the fiscal year.

**Fields.**

| Field | Meaning |
| --- | --- |
| RoleName | Role. |
| ChangeNumber | Change document. |
| TableName | Table inside the role, such as `AGR_USERS` for assignments or `AGR_1251` for values. |
| TableKey | Key of the changed line. |
| FieldName | Field that changed. |
| ItemChange | `I` or `J` insert, `U` update, `D` or `E` delete. |
| HeaderChange | Change type on the document header. |
| ChangedBy, ChangeDate, ChangeTime | Who, and when. |
| TransactionCode | Transaction used. |
| ValueOld, ValueNew | Value before and after. Blanked when the field is a password or address field. |

**Logic.** One change document is many rows that share `RoleName` and `ChangeNumber`. `TableName` says which part of the role changed. Current contents are F.26, not this history.

## F.24 System change options

**Purpose.** Shows whether this system is open for repository changes and for client-independent customizing. A production system is expected to be closed.

**Data.** `SystemChangeOptions` on `ZAPI_SEC_SETTINGS`.

**Fields.**

| Field | Meaning |
| --- | --- |
| SettingScope | `Global`, `SoftwareComponent`, or `Namespace`. |
| ObjectName | Software component or namespace the switch applies to. |
| ChangeOption | Whether change is allowed. |
| ChangeOptionText | Plain-language setting. |

**Logic.** No join. Read the global switch and the rows for individual components. F.11 is the client-level change switch, which is separate.

## F.25 Profile changes

**Purpose.** Who changed an authorization profile during the fiscal year, and when.

**Data.** `ProfileChangeDocuments` on `ZAPI_SEC_ACCESS`, from `USH10`. `ChangedOn` needs a start and an end.

**Fields.**

| Field | Meaning |
| --- | --- |
| ProfileName | Profile. |
| Version | Profile version on that history record. |
| ChangedOn, ChangedAt | When. |
| ChangedBy | Who. |

**Logic.** One row is a history header, the population report `RSUSR101` reads. The added and removed authorization values (`USH12`) are not on the row.

## F.26 Role authorization values

**Purpose.** Every field value stored on roles. The critical-authorization controls read this list.

**Data.** `RoleAuthorizations` on `ZAPI_SEC_ACCESS`, from `AGR_1251`.

**Fields.**

| Field | Meaning |
| --- | --- |
| RoleName | Role that holds the value. |
| Counter | One authorization inside the role. Fields with the same counter belong together. |
| Object | Authorization object, such as `S_TCODE`. |
| AuthName | Authorization name inside the role. |
| Field | Field of the object, such as `TCD` or `ACTVT`. |
| Low, High | Stored range for that field. |
| Modified, Deleted, Copied, NewEntry | How the value was maintained in PFCG. |
| Variant | Organizational or derived variant. |

**Logic.** This export is the raw list. F.27 to F.39 select from it. Do not treat two fields as one authorization unless `RoleName` and `Counter` match.

## F.27 SU24 maintenance

**Purpose.** Finds users who can start SU24 and change the default values of a transaction (`SUSK`) or a service (`SUST`). Those defaults are what PFCG proposes when the transaction or service is added to a role.

**Data.** `RoleAuthorizations` and `AuthorizationValues` for objects `S_TCODE` and `S_DEVELOP`. `ProfileAuthorizations` for those objects at `Version` `A`. `RoleAssignments` and `ProfileAssignments`.

**Fields.** Use the fields in F.26, F.18, F.49, and F.65. `Object`, `Field`, `Low`, `High`, `RoleName`, `Counter`, `AuthName`, `ProfileName`, and `UserId` are the ones the rule reads.

**Logic.** Use [How a user receives access](#how-a-user-receives-access). A role or profile is in scope when it has both of these:

- `S_TCODE` / `TCD` matching `SU24`.
- `S_DEVELOP` / `OBJTYPE` matching `SUSK` or `SUST`, and `S_DEVELOP` / `ACTVT` matching `01` or `02`, on the same authorization.

Then list the users who have that role or that profile.

## F.28 SAP_ALL

**Purpose.** Finds users with profile `SAP_ALL`. That profile grants full authorization.

**Data.** `ProfileAssignments` with `ProfileName` `SAP_ALL` and `ProfileSource` `Assigned`.

**Fields.** `UserId` is the account. `ProfileName` is `SAP_ALL`.

**Logic.** No value test. The assignment itself is the result. Also check `ProfileSource` `ReferenceUser` when the review includes inherited profiles.

## F.29 SAP_APP

**Purpose.** Finds users with role `SAP_APP`, a broad application role.

**Data.** `RoleAssignments` with `RoleName` `SAP_APP`.

**Fields.** `UserId`, `RoleName`, `ValidFrom`, `ValidTo`, `Excluded`.

**Logic.** Keep rows in validity with `Excluded` blank. An empty result is a valid outcome and should be kept as evidence.

## F.30 SAP_NEW

**Purpose.** Finds users who still have profile or role `SAP_NEW`. That content is delivered for a new release and is not meant to stay assigned.

**Data.** `ProfileAssignments` for profile `SAP_NEW`, and `RoleAssignments` for role `SAP_NEW`.

**Fields.** `UserId` plus `ProfileName` or `RoleName`.

**Logic.** The two results are separate populations. A user can appear in one or both. Apply the validity and `Excluded` test to the role rows.

## F.31 Standard basis profiles

**Purpose.** Finds users assigned to wide standard basis profiles.

**Data.** `ProfileAssignments` with `ProfileSource` `Assigned`, one filter per profile: `S_A.SYSTEM`, `S_A.ADMIN`, `S_A.DEVELOP`, `S_A.CUSTOMIZ`, `S_A.USER`, `F_SYS_ADMIN`, `S_ABAP_ALL`, `S_ADMI_ALL`, `S_SYST_ALL`.

**Fields.** `UserId` and `ProfileName`.

**Logic.** Each profile is its own result. The profile name is the finding. An empty result for a profile is a valid outcome.

## F.32 Debug, activity 01

**Purpose.** Finds users who can start the debugger (`S_DEVELOP`, object type `DEBUG`, activity `01`).

**Data.** `RoleAuthorizations` and `AuthorizationValues` for `S_DEVELOP`. Then `RoleAssignments` or `ProfileAssignments` for each match.

**Fields.** `Object`, `Field`, `Low`, `RoleName` or `AuthName`, `Counter`, `UserId`.

**Logic.** Use the access join. Keep a role whose one authorization has `OBJTYPE` `DEBUG` and `ACTVT` `01`. On the profile side, keep an `AuthName` that has both field values, then the profiles at version `A` that contain it, then the users who have those profiles.

## F.33 Debug, activity 02

**Purpose.** Finds users who can change values in the debugger (`ACTVT` `02`).

**Data.** Same sets as F.32.

**Fields.** Same fields as F.32.

**Logic.** Same join as F.32, with `ACTVT` `02` instead of `01`.

## F.34 Debug change plus SE11 or SE13

**Purpose.** Finds users who can change debugger values and can also start SE11 or SE13.

**Data.** Same sets as F.32, plus `S_TCODE`.

**Fields.** Same fields as F.32. `TCD` is the transaction field.

**Logic.** The role or profile must have all of: `S_DEVELOP` object type `DEBUG`, `S_DEVELOP` activity `02` on that same authorization, and `S_TCODE` `SE11` or `SE13`. Then list its users.

## F.35 Authorization object and service defaults

**Purpose.** Finds users who can create or change authorization objects (`SUSO`) or service authorization defaults (`SUST`).

**Data.** Same sets as F.32, object `S_DEVELOP`.

**Fields.** Same fields as F.32.

**Logic.** One authorization must have `OBJTYPE` `SUSO` or `SUST` and `ACTVT` `01` or `02`. Then list the users of that role or profile.

## F.36 Table maintenance across groups

**Purpose.** Finds users who can change tables in every authorization group and maintain client-independent tables.

**Data.** Role and profile value sets for `S_TABU_DIS` and `S_TABU_CLI`, then the assignment sets.

**Fields.** `DICBERCLS` is the table authorization group. `ACTVT` is the activity. `CLIIDMAINT` is client-independent maintenance.

**Logic.** The role or profile needs all three: `S_TABU_DIS` group `*`, `S_TABU_DIS` activity `02` on that same authorization, and `S_TABU_CLI` value `X`. Then list its users.

## F.37 Change document objects

**Purpose.** Finds users who can maintain change-document objects and start SCDO. Those objects decide which data changes are logged.

**Data.** Value sets for `S_SCD0` and `S_TCODE`, then the assignment sets.

**Fields.** `ACTVT` `12` on `S_SCD0`. `TCD` `SCDO` on `S_TCODE`.

**Logic.** The role or profile needs both. Then list its users.

## F.38 Profile administration

**Purpose.** Finds users who can create profiles or assign them to users.

**Data.** Value sets for `S_USER_PRO`, then the assignment sets.

**Fields.** `ACTVT` `01` create or `22` assign.

**Logic.** Keep each role or profile that has either activity, then list its users. `01` and `22` are separate findings if the review splits them.

## F.39 Authorization maintenance

**Purpose.** Finds users who can create or activate authorizations.

**Data.** Value sets for `S_USER_AUT`, then the assignment sets.

**Fields.** `ACTVT` `01` create or `07` activate.

**Logic.** Same shape as F.38, for `S_USER_AUT`.

## F.40 Client setting changes

**Purpose.** Shows whether the client settings in `T000` changed during the fiscal year, for example a production client opened for changes.

**Data.** `TableChangeLogs` on `ZAPI_SEC_SETTINGS`, from `DBTABLOG`. Filter `TableName` `T000` and `LogDate` to the fiscal year.

**Fields.**

| Field | Meaning |
| --- | --- |
| TableName | `T000` for this control. |
| LogDate, LogTime | When the change was logged. |
| LogId | Id of the log record. |
| RecordKey | Key of the changed client row. |
| UserName | User who made the change. |
| TransactionCode | Transaction used. |
| ProgramName | Program used. |
| Operation | `I` insert, `U` update, `D` delete. |
| OperationText | Plain-language operation. |
| HostName | Application server. |

**Logic.** One row is one logged change. The binary image of the changed row is not returned, so the old and new SCC4 values are not in the export. Archived logs are not in this set. If F.15 shows logging off for `T000`, an empty log does not prove that nothing changed.

## F.41 Profile parameters in force

**Purpose.** The parameter values in force on this application server: kernel default and instance value. This is the baseline for password, logon, and system parameters.

**Data.** `SecurityProfileParameters` on `ZAPI_SEC_SETTINGS`.

**Fields.**

| Field | Meaning |
| --- | --- |
| ParameterName | Parameter. |
| KernelDefaultValue | Default compiled into the kernel. |
| InstanceProfileValue | Value from the instance profile. Empty when the profile does not set it. |
| Description | Parameter text. |
| DynamicallyChangeable | Whether it can be changed without a restart. |
| SecurityRelevant, SecurityArea | Security classification. |
| ApplicationServer | Server the value was read from. |

**Logic.** The value in force is `InstanceProfileValue` when filled, otherwise `KernelDefaultValue`. F.7 is the single parameter `rec/client`. F.16 is the history. F.9 may override a parameter for users of a security policy.

## F.42 User master changes

**Purpose.** Who created, locked, or changed an account during the fiscal year, including role and profile assignment changes.

**Data.** `UserChangeDocuments` on `ZAPI_SEC_ACCESS`. Filter `ChangeDate` from the first day of the fiscal year. Profile assignment lines are `TableName` `SUSR_UST04`.

**Fields.**

| Field | Meaning |
| --- | --- |
| UserId | Account that was changed. |
| ChangeNumber | Change document. |
| TableName | Part of the user master. `USR02` is logon data, `AGR_USERS` is role assignment, `SUSR_UST04` is profile assignment. |
| FieldName | Field that changed. |
| ItemChange | `I` or `J` insert, `U` update, `D` or `E` delete. |
| ValueOld, ValueNew | Value before and after. Password and address values are blanked. |
| ChangedBy, ChangeDate, ChangeTime | Who, and when. |
| TransactionCode | Transaction used, such as SU01. |

**Logic.** Rows that share `UserId` and `ChangeNumber` are one document. Current assignments are F.49 and F.18. This set is the history.

## F.43 Standard users

**Purpose.** Shows the well-known standard accounts and whether they are locked. The review expects `SAP*`, `DDIC`, `SAPCPIC`, `EARLYWATCH`, and `TMSADM` not to be left open.

**Data.** `Users`, filtered to those five user ids.

**Fields.** The F.13 fields, in particular `UserType`, `GloballyLocked`, `LocallyLocked`, `PasswordState`, and `LastLogonDate`.

**Logic.** One row per account that exists. A missing user id means that account is not in this client. The RSUSR003 default-password test is not a separate result. `PasswordState` says whether a password is initial. It does not say whether the password is a known default.

## F.45 Audit log configuration

**Purpose.** Shows the static and dynamic SM19 filters, and which events each active filter records. Events are written only for filters that are switched on.

**Data.** `AuditConfiguration` for the static profile headers. `AuditFilterEvents` for the selected events of each static filter and for the dynamic filters of the server that answered.

**Fields.**

| Field | Meaning |
| --- | --- |
| ProfileName | Static profile. `$CURPROF$` is the pointer to the loaded profile, stored in `ActiveProfile`. |
| SlotNumber | `0000` is the profile header. A higher number is one filter. |
| SlotStatus | `X` means the filter is active. |
| AuditClasses | Bit mask of audit classes. `0` together with `Severity` `0` means the filter uses a detailed event list. |
| AuditClassText | Class names, or `Detailed events`. |
| Severity, SeverityText | `2` low, `5` medium, `9` high. |
| Client, UserName | Client and user the filter restricts, when set. |
| Source | `Static` or `Dynamic` on the event rows. |
| LineKind | `Event` one message id, `Class` a whole class, `Filter` a slot with nothing selected. |
| LineValue | Message id such as `EUH`, or a class name such as `Logon`. |
| HostName | Server, filled for dynamic rows. |

**Logic.** Join static event rows to headers on `ProfileName` and `SlotNumber`. Ignore profiles `$KERNEL$`, `$CURPROF$`, `$FLAG$`, and `$CONFIG$` as filters. `$KERNEL$` rows are recording parameters. Dynamic rows have an empty `ProfileName` and belong to `HostName`. The message text shown on the SM19 screen is not in the row.

## F.46 Security audit log

**Purpose.** The trail of security-relevant actions recorded during the fiscal year, for every client and every user unless the review names one.

**Data.** `AuditEvents` on `ZAPI_SEC_ACCESS`. `EventOn` needs a start and an end. Omit `Client` and `UserName` for all clients and all users.

**Fields.**

| Field | Meaning |
| --- | --- |
| MessageId | Event, three characters, such as `AUG` or `FUJ`. |
| MessageArea, MessageSubid | The same id split in two. |
| EventTimestamp | Date and time, 16 characters. |
| EventOn | The date inside that timestamp. This is the period filter. |
| Client | Client of the event. Blank on many system events. |
| UserName | User. Blank on system events such as server start. |
| SystemId | System. From the file, this is the local system. |
| InstanceName | Application server. |
| Terminal | Terminal or caller address stored on the event. |
| TransactionCode | Transaction, such as `SE37`. |
| ProgramName | ABAP program. |
| EventData | Variable values of the message, not the message sentence SM20 displays. |
| Counter | Counter from the database buffer. `0` on a row that came from the audit file. |

**Logic.** The service reads the audit files with `RSAU_READ_FILE` and the database buffer `RSAU_BUF_DATA`. A row that is in both is returned once. The read is the server that answered. Another application server needs its own call. The files may not cover the whole fiscal year, which is the same limit SM20 shows as "period selected". Join `MessageId` to F.45 `LineValue` to see whether an active filter selected that event.

## F.47 System log

**Purpose.** Failed logons, locked users, and debugger activity in the system log, as messages `A14`, `A19`, and `A23`.

**Data.** `SystemLog` on `ZAPI_SEC_ACCESS`. `EventOn` needs a start and an end. Filter `MessageId` to those three values.

**Fields.**

| Field | Meaning |
| --- | --- |
| MessageId | `A14`, `A19`, or `A23` for this control. |
| EventOn, EventAt | Date and time. |
| InstanceName | Server whose local log was read. |
| Client, UserName | Client and user on the message. |
| TransactionCode, ProgramName, Terminal | Context stored on the message. |
| MessageData | Variable data of the message. |
| FileNumber, FilePosition | Position in the local log file. |

**Logic.** No join. The read is the local file of the server that answered. That file often does not keep a full fiscal year. Other servers are not included.

## F.48 Program change facts

**Purpose.** Last change of the named programs and of their includes. A local change to one of these programs affects the report the review relies on.

**Data.** `Programs` and `ProgramIncludes` on `ZAPI_SEC_SETTINGS`. A `ProgramName` filter is required. Run one call per program name.

**Fields.**

| Field | Meaning |
| --- | --- |
| ProgramName | Program. |
| ProgramType, ProgramTypeText | Kind of program. |
| CreatedBy, CreatedOn | Original author and date. |
| ChangedBy, ChangedOn | Last change. |
| Version | Program version. |
| AuthorizationGroup | Authorization group of the program. |
| IncludeName | One include of the program, from `ProgramIncludes`. |

**Logic.** Join `ProgramIncludes.ProgramName` to `Programs.ProgramName`. The source code is not returned. `ChangedOn` of the program and of each include is the evidence of a change.

## F.49 Role assignments

**Purpose.** The roles assigned to each user, with validity. This is the population for a role-based access review.

**Data.** `RoleAssignments` on `ZAPI_SEC_ACCESS`.

**Fields.**

| Field | Meaning |
| --- | --- |
| UserId | User. |
| RoleName | Assigned role. |
| ValidFrom, ValidTo | Assignment interval. |
| Excluded | Role removed from a composite for this user. |
| FromCompositeRole | Single role received through a composite. |
| FromOrgManagement | Assigned by organizational management. |
| ChangedOn | Date stored on the assignment. |

**Logic.** Keep rows in validity with `Excluded` blank. Join `RoleName` to F.26 for the values, and to `RoleHierarchy` when `FromCompositeRole` is `X`.

## F.50 Profiles with debug change

**Purpose.** Profiles that allow changing values in the debugger. The same right as F.33, read from the profile side only.

**Data.** `AuthorizationValues` for `S_DEVELOP` object type `DEBUG` and activity `02`. `ProfileAuthorizations` for `S_DEVELOP` at version `A`.

**Fields.** `Object`, `AuthName`, `Version`, `Field`, `Low`, `High`, `ProfileName`.

**Logic.** Keep an `AuthName` that has both field values. `ProfileAuthorizations` links that `AuthName` to `ProfileName`. Users of those profiles are F.18, and are a second step this control does not require.

## F.51 Profiles that change authorization objects

**Purpose.** Profiles that can create or change authorization objects (`SUSO`) or service defaults (`SUST`). The profile-side form of F.35.

**Data.** `AuthorizationValues` for `S_DEVELOP` object type `SUSO` or `SUST` and activity `01` or `02`. `ProfileAuthorizations` for the matching `AuthName`.

**Fields.** Same fields as F.50.

**Logic.** Same join as F.50. The authorization must contain both the object type and the activity.

## F.52 Profiles with debug activity 01

**Purpose.** Profiles that can start the debugger. The profile-side form of F.32.

**Data.** `AuthorizationValues` for `S_DEVELOP` object type `DEBUG` and activity `01`, then `ProfileAuthorizations`.

**Fields.** Same fields as F.50.

**Logic.** Same join as F.50, with activity `01`.

## F.53 Profiles with wide table maintenance

**Purpose.** Profiles that can change every table group and maintain client-independent tables. The profile-side form of F.36.

**Data.** `AuthorizationValues` for `S_TABU_DIS` group `*` and activity `02`, and for `S_TABU_CLI` value `X`. `ProfileAuthorizations` for those objects.

**Fields.** Same value fields as F.50. The objects are `S_TABU_DIS` and `S_TABU_CLI`.

**Logic.** All three field conditions must land on the same profile. The two `S_TABU_DIS` fields must be the same `AuthName`.

## F.54 Profiles that maintain change documents

**Purpose.** Profiles that can maintain change-document objects and start SCDO. The profile-side form of F.37.

**Data.** `AuthorizationValues` for `S_SCD0` activity `12` and `S_TCODE` `SCDO`. `ProfileAuthorizations`.

**Fields.** Same value fields as F.50.

**Logic.** Both results must name authorizations of the same profile.

## F.55 Profiles that administer profiles

**Purpose.** Profiles that can create profiles or assign them. The profile-side form of F.38.

**Data.** `AuthorizationValues` for `S_USER_PRO` activity `01` or `22`. `ProfileAuthorizations`.

**Fields.** Same value fields as F.50.

**Logic.** A profile that has either activity is in scope.

## F.56 Profiles that maintain authorizations

**Purpose.** Profiles that can create or activate authorizations. The profile-side form of F.39.

**Data.** `AuthorizationValues` for `S_USER_AUT` activity `01` or `07`. `ProfileAuthorizations`.

**Fields.** Same value fields as F.50.

**Logic.** A profile that has either activity is in scope.

## F.57 Transport tool parameters

**Purpose.** Shows the transport-tool parameters, including the settings that control how transports are imported.

**Data.** `TpParameters` on `ZAPI_SEC_SETTINGS`, from `TMSPCONF`, newest version.

**Fields.**

| Field | Meaning |
| --- | --- |
| DomainName | Transport domain. |
| ConfigVersion | Configuration version. Keep the newest. |
| SystemName | System the parameter applies to. Blank means the parameter is global. |
| ParameterName | Parameter (`NAME`). |
| ParameterValue | Value (`VALUE`). |
| OperatingSystem, DatabaseSystem | Platform the parameter is stored for. |

**Logic.** Join `DomainName` to F.4. Within one domain, keep the highest `ConfigVersion`.

## F.58 Transport requests

**Purpose.** Requests changed in this system during the fiscal year: owner, type, and status. This is the change population, not the import history.

**Data.** `TransportRequests` on `ZAPI_SEC_SETTINGS`, from `E070`. `ChangedOn` needs a start and an end.

**Fields.**

| Field | Meaning |
| --- | --- |
| Request | Request id. |
| Description | Short text. |
| Owner | Owner. |
| RequestFunction, RequestFunctionText | Workbench, customizing, or other request kind. |
| RequestStatus, RequestStatusText | Modifiable, released, or another status. |
| TargetSystem | Target named on the request. |
| ChangedOn, ChangedAt | Last change in this system. This is the period filter. |
| ParentRequest | Parent request, when this row is a task. |

**Logic.** Filter `ChangedOn` to the fiscal year. F.6 shows what was imported. F.59 shows the objects inside these requests. Join `Request` across those sets.

## F.59 Objects in transport requests

**Purpose.** Which programs, tables, and customizing entries each request from F.58 contains.

**Data.** `TransportRequestObjects` on `ZAPI_SEC_SETTINGS`, from `E071` with the `E070` header. Use the same `ChangedOn` period as F.58.

**Fields.**

| Field | Meaning |
| --- | --- |
| Request | Request. Join to F.58. |
| ObjectPosition | Position of the object in the request. |
| ProgramId | Program id, such as `R3TR` or `LIMU`. |
| ObjectType | Object type, such as `PROG` or `TABU`. |
| ObjectName | Object name. |
| ObjectFunction | Whether the object was added or deleted. |
| Owner, ChangedOn, RequestStatus, TargetSystem, Description | Header facts copied onto the object row. |

**Logic.** The service already keeps only objects whose request header matches the `ChangedOn` filter. Group by `Request` to see the contents of one change.

## F.61 Composite role membership

**Purpose.** Which single roles belong to each composite role. A user who has the composite receives every single role in the list.

**Data.** `RoleHierarchy` on `ZAPI_SEC_ACCESS`, from `AGR_AGRS`. The service returns the current membership. It does not filter by a from-date.

**Fields.**

| Field | Meaning |
| --- | --- |
| CompositeRole | Composite role. |
| SingleRole | Single role inside it. |

**Logic.** Join `CompositeRole` to `RoleAssignments.RoleName` where `FromCompositeRole` is blank and the row is the composite assignment. The single roles are also on `RoleAssignments` with `FromCompositeRole` `X`.

## F.62 SNC names

**Purpose.** The SNC name stored for each user, and whether a password logon is still allowed beside SNC.

**Data.** `SncNames` on `ZAPI_SEC_ACCESS`, from `USRACL`.

**Fields.**

| Field | Meaning |
| --- | --- |
| UserName | User. Join to F.13. |
| SncName | Printable SNC name. |
| GuiPasswordLogon | `X` means a password logon is also allowed. |
| SecuritySystem | System id stored on the SNC record. |
| CreatedBy, CreatedOn, ChangedBy, ChangedOn | Who maintained the record, and when. |

**Logic.** No join required for the control. Hashes are not in the row.

## F.63 Object access registrations

**Purpose.** Repository objects registered for an object access key. The key value is not exported.

**Data.** `ObjectAccessRegistrations` on `ZAPI_SEC_ACCESS`, from `ADIRACCESS`.

**Fields.**

| Field | Meaning |
| --- | --- |
| ProgramId | Program id of the object. |
| ObjectType | Object type. |
| ObjectName | Object name. |

**Logic.** The row exists because a key was entered. The key is not in the export. Join `ObjectName` to F.59 when the review asks whether a registered object was also transported.

## F.64 Profile assignment history

**Purpose.** Profiles that were on each user during the fiscal year, including assignments that are gone today.

**Data.** `ProfileAssignmentHistory` on `ZAPI_SEC_ACCESS`, from `USH04`. `ChangedOn` needs a start and an end.

**Fields.**

| Field | Meaning |
| --- | --- |
| UserName | User. |
| ChangedOn, ChangedAt | When this snapshot was written. |
| ChangedBy | Who changed the profile list. |
| ProfileCount | Number of profiles in the snapshot. |
| ProfileList | Profile names stored on that change. |

**Logic.** One row is one historical list, not one profile. Compare `ProfileList` with F.18 to see assignments that no longer exist. The current list is not a substitute for this history.

## F.65 Profile field values

**Purpose.** Every field value stored on profile authorizations. F.50 to F.56 read this list.

**Data.** `AuthorizationValues` on `ZAPI_SEC_ACCESS`, from `UST12`.

**Fields.**

| Field | Meaning |
| --- | --- |
| Object | Authorization object. |
| AuthName | Authorization that holds the value. |
| Version | `A` active, `P` maintenance copy. Use `A` for the check. |
| Field | Field name. |
| Low, High | Stored range. |
| Client | Client. |

**Logic.** This is the raw list. A profile name is not on the row. `ProfileAuthorizations` supplies it: same `Object`, `AuthName`, and `Version`.

## F.66 Composite profiles

**Purpose.** Which single profiles belong to each composite profile. A composite grants every single profile in the list.

**Data.** `CompositeProfiles` on `ZAPI_SEC_ACCESS`, from `UST10C`. Keep `Version` `A`.

**Fields.**

| Field | Meaning |
| --- | --- |
| ProfileName | Composite profile. |
| SubProfile | Single profile inside it. |
| Version | `A` active, `P` maintenance. |

**Logic.** Join `SubProfile` to F.18 `ProfileName` to see users who hold a single profile directly. A user who holds `ProfileName` also receives each `SubProfile`. This set is not the authorization rows of F.65.

## F.66 Profile authorizations

The spreadsheet numbers this row F.66 as well. It is the export of `UST10S`, not `UST10C`.

**Purpose.** Which authorization objects and authorization names each profile contains. Read with F.65, it is the contents of the profile.

**Data.** `ProfileAuthorizations` on `ZAPI_SEC_ACCESS`, from `UST10S`.

**Fields.**

| Field | Meaning |
| --- | --- |
| ProfileName | Profile. |
| Version | `A` active. |
| Object | Authorization object. |
| AuthName | Authorization inside the profile. Join to F.65. |

**Logic.** Join `Object`, `AuthName`, and `Version` to `AuthorizationValues`. The field values are not on this row. Users of `ProfileName` are F.18.
