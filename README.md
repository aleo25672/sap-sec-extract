# SAP security settings extract

Read-only OData V4 service for the profile parameters shown by report RSPFPAR, plus the four settings that sit beside that report and change an IT general control conclusion: security policies, client settings, system change options, and parameter history.

The service returns raw values and, where a value is derived, the derivation. The caller compares a policy with the application server and decides whether a production client is locked.

Activate this package on S/4HANA 1909 (ABAP platform 7.54) or later, on-premise or private cloud. It is not ABAP Cloud. `CL_SPFL_PROFILE_PARAMETER` is the class RSPFPAR uses, and it is not a released Cloud API.

The same repository contains a second service, `ZAPI_SEC_ACCESS`, for the account and assignment population. That service is documented under [Security access extract](#security-access-extract).

## Entity sets

Published service:

`/sap/opu/odata4/sap/zapi_sec_settings/srvd_a2x/sap/zapi_sec_settings/0001/`

| Entity set | Source | What a row is |
| --- | --- | --- |
| `SecurityProfileParameters` | RSPFPAR, current application server | Kernel default and the user-defined value, side by side |
| `SecurityPolicies` | SECPOL, logon client | Policy header and assigned-user count |
| `SecurityPolicyAttributes` | SECPOL attributes | Effective value and whether it was stored on the policy or taken from the kernel default |
| `ClientSettings` | SCC4 / `T000` | One row per client |
| `SystemChangeOptions` | SE06 | Global row, software components, and namespaces |
| `ProfileParameterChanges` | TU02 / `PAHI` | Parameter history for a host and a date |

`SecurityProfileParameters` keeps three value fields:

- `KernelDefaultValueRaw` is the RSPFPAR column "System Default Value (Unsubstituted Form)".
- `KernelDefaultValue` is the substituted kernel default.
- `InstanceProfileValue` is the RSPFPAR column "User-Defined Value". It is filled from `DEFAULT.PFL`, the instance profile, or a dynamic RZ11 change. It is empty when this server is still on the kernel default.

The service does not choose which of those is in force.

`SecurityPolicyAttributes.ValueOrigin` is `Policy` when `SEC_POLICY_RT` stores the attribute, and `KernelDefault` when it does not. `EffectiveValue` is the stored value or `SEC_POLICY_ATTR-DEFAULT_VALUE`. `ProfileParameter` is the join key to `SecurityProfileParameters.ParameterName`. An attribute the policy does not store applies the kernel default to assigned users, not the instance profile value. SAP documents that as the designed behavior (KBA 3636563, KBA 3075533). Users with no policy still use the instance profile. Parameters with no SECPOL attribute, such as `login/no_automatic_user_sapstar`, also stay on the instance profile.

`DISABLE_PASSWORD_LOGON` also supersedes `login/password_logon_usergroup`. The payload carries the single profile parameter name stored on `SEC_POLICY_ATTR`.

A landscape pull is one call per application server. Policy and client data are for the logon client (`sap-client`) or, for `T000`, every client. There is no RFC to other instances.

## IT general controls

RSPFPAR is the current profile of this application server. These four entity sets are the settings that report does not show. Read together, they are the evidence for two SOX IT general controls: access to programs and data, and change management.

| Entity sets | IT general control | What it adds to RSPFPAR |
| --- | --- | --- |
| `SecurityPolicies`, `SecurityPolicyAttributes` | Access to programs and data | Password and logon rules for users who have a security policy |
| `ClientSettings` | Change management | Whether this client allows customizing, repository changes, a client copy, or eCATT |
| `SystemChangeOptions` | Change management | Whether the system as a whole allows repository and cross-client changes |
| `ProfileParameterChanges` | Change management, and access to programs and data | Which security parameters changed, on which host, and on which date |

### Security policies

`SecurityPolicies` and `SecurityPolicyAttributes` are transaction SECPOL for the logon client. A policy is assigned to a user in SU01. For every attribute that policy covers, the user follows the policy instead of the `login/*` profile parameters.

`EffectiveValue` is the stored attribute when `ValueOrigin` is `Policy`. It is the kernel default when `ValueOrigin` is `KernelDefault`. An attribute the policy does not store applies that kernel default, including when this server has a stricter instance profile. SAP documents that as the designed behavior (KBA 3636563, KBA 3075533). Parameters with no SECPOL attribute, such as `login/no_automatic_user_sapstar`, stay on the instance profile for those users. Users with no policy stay on the instance profile.

The access-control test joins `SecurityPolicyAttributes.ProfileParameter` to `SecurityProfileParameters.ParameterName`. On the profile row, the value in force on this server is `InstanceProfileValue` when that field is filled, and `KernelDefaultValue` when it is empty. The caller compares that value with `EffectiveValue`. `AssignedUserCount` shows how many users in this client have the policy. User ids are not in the extract.

### Client settings

`ClientSettings` is transaction SCC4, one row per client in `T000`.

The row says whether the client allows client-specific customizing, cross-client customizing, repository changes, a client copy, and eCATT. `LastChangedBy` and `LastChangedOn` are the last time those switches were saved, which is the evidence that a production client was opened. They are not a history of every open and close.

A production client is usually role `P`, client-specific changes `2` (no changes allowed), cross-client changes `3` (no repository and no cross-client customizing), copy protection `X` or `L`, and eCATT not allowed. The service returns the codes and the texts.

Table logging of the client record is `TableChangeLogging` together with profile parameter `rec/client` on `SecurityProfileParameters`. The logging flag is the same on every client row. `rec/client` stays on the profile entity.

### System change options

`SystemChangeOptions` is transaction SE06. It is one setting for the whole system, shared by every client. SCC4 cannot close it.

The `Global` row is modifiable or not modifiable. While it is not modifiable, software components and namespaces cannot be changed. The service still returns those component and namespace rows as they are stored. The caller reads the global `ChangeOption` and applies that lock.

A production client can be closed in SCC4 while this global row is still modifiable. The change-management conclusion uses `ClientSettings` and `SystemChangeOptions` together.

### Profile parameter changes

`ProfileParameterChanges` is transaction TU02, table `PAHI`. A row is a parameter value on a host on a date. `SecurityRelevant` uses the same classification as RSPFPAR, so a change to `login/*` or another security prefix is marked on the history row. Join `ParameterName` to `SecurityProfileParameters` for the current value on this server.

This is the population of security-parameter changes in the audit period. The store keeps a day and a 64-character value. It does not keep the user or the time. The account that saved an RZ10 change is in the profile comment. A dynamic RZ11 change is system log message Q19. The newest day appears after the TU02 changelog update.

## Authorization

| Entity sets | Check |
| --- | --- |
| `SecurityProfileParameters`, `ProfileParameterChanges` | `S_ADMI_FCD` / `PADM` |
| `SecurityPolicies`, `SecurityPolicyAttributes` | `S_SECPOL` activity 03 |
| `ClientSettings` | `S_TABU_NAM` for `T000`, activity 03 |
| `SystemChangeOptions` | `S_CTS_ADMI` function `TABL`. Report `RSWBO004` uses that function for the SE06 display. Confirm it on the target system. |

A failed check is an OData error. The response is not an empty list.

`AssignedUserCount` is filled only when `S_USER_GRP` activity 03 is granted for user group `*`. Otherwise `UsersCounted` is blank and the count is empty. User ids are not returned.

## Filters

Range filters, `$select`, `$orderby`, `$top`, `$skip`, and `$count`. Every property of an entity accepts a range filter. A filter on an unknown property is an error (message 004). Character comparisons are case-insensitive, and a blank flag matches an empty value. `gt`, `ge`, `lt`, `le`, and `bt` compare integers numerically when both sides are integers, so 10 is greater than 2.

```http
GET .../SecurityProfileParameters?$filter=SecurityRelevant eq 'X'&$count=true
GET .../SecurityProfileParameters?$filter=startswith(ParameterName,'login/')
GET .../SecurityPolicyAttributes?$filter=ValueOrigin eq 'KernelDefault'
GET .../ClientSettings?$filter=ClientRole eq 'P'
GET .../SystemChangeOptions?$filter=SettingScope eq 'Global'
GET .../ProfileParameterChanges?$filter=ChangeDate ge 2026-01-01 and ParameterName eq 'login/min_password_lng'
```

`ProfileParameterChanges` pushes the host, parameter name, date, and parameter type filters into the `PAHI` select. Character filters are applied with `upper`, so the name match is case-insensitive. An empty range does not restrict the select. Pass a date or name filter. The table also holds database and operating-system parameters. The entity key is host, parameter name, date, parameter type, and system id, which is the `PAHI` key. `PAHI-SYSTEMID` is CHAR 2; the property is 8 characters so the value is not clipped. `ParameterValue` is 64 characters. The row has a date and no time, and it has no user. The newest day appears only after the TU02 changelog update.

`ParameterStatus` and `StatusText` repeat the raw `SPFL_PARAMETER_LIST-STATE`. The numeric legend is release-specific, so the service does not translate it.

## Pull and activate

One abapGit pull loads both services into package `$ZEVOLVER_SEC2F` from branch `main`. The master language is English. The package object stored in the repository is `ZSEC_SETTINGS`; this installation assigns the pulled objects to `$ZEVOLVER_SEC2F`.

### abapGit

1. Open abapGit (transaction `ZABAPGIT`).
2. Add the GitHub repository `https://github.com/aleo25672/sap-sec-extract.git` as an online repository, or open it if it is already linked. The same commits are on the Cursor remote `evolver/sap-sec-extract`.
3. Select branch `main`.
4. Set the package to `$ZEVOLVER_SEC2F` and the master language to English.
5. If an earlier pull left service definition `ZAPI_SEC_ACCESS` without a source, delete `R3TR SRVD ZAPI_SEC_ACCESS` before pulling. Delete it in ABAP Development Tools or SE80 when the object opens. When it does not open, delete that directory entry in SE03, Change Object Directory Entries.
6. Pull, then activate the imported objects.

The interface views `ZI_SEC_USER`, `ZI_SEC_ROLE_ASSIGN`, `ZI_SEC_PROF_ASSIGN`, `ZI_SEC_ROLE`, `ZI_SEC_ROLE_HIER`, and `ZI_SEC_ROLE_PROFILE` activate with a warning. Their tables (`USR02`, `UST04`, `AGR_USERS`, `AGR_DEFINE`, `AGR_AGRS`, `AGR_1016`) are client-dependent, and the logon client is applied by the session. The warning leaves the views active.

The pull imports service definition `ZAPI_SEC_SETTINGS`. Create service definition `ZAPI_SEC_ACCESS` in ABAP Development Tools, using the source below. Leaving it in the repository makes the pull raise `An exception was raised` and report `Import of object ZAPI_SEC_ACCESS failed`.

The pull also leaves out both service bindings. On S/4HANA 1909, abapGit creates a binding through a workbench BAdI that has no implementation, and that error stops the pull. Create the bindings in ABAP Development Tools.

### ABAP Development Tools

Create the following objects in package `$ZEVOLVER_SEC2F` after the pull has activated.

**Service definition `ZAPI_SEC_ACCESS`.** In the project, choose New > Other ABAP Repository Object > Service Definition. Name it `ZAPI_SEC_ACCESS`, assign package `$ZEVOLVER_SEC2F`, and replace the generated source with:

```cds
@EndUserText.label: 'Security access'
define service ZAPI_SEC_ACCESS {
  expose ZC_SEC_USER         as Users;
  expose ZC_SEC_ROLE_ASSIGN  as RoleAssignments;
  expose ZC_SEC_PROF_ASSIGN  as ProfileAssignments;
  expose ZC_SEC_ROLE         as Roles;
  expose ZC_SEC_ROLE_HIER    as RoleHierarchy;
  expose ZC_SEC_ROLE_PROFILE as RoleProfiles;
}
```

Activate it. `Client` on these entities is a 3-character client id. `ClientSettings` keeps `abap.clnt` because there the client is the key. When the definition already exists, add the `RoleProfiles` line to its source and activate it again. The binding stays as it is.

**Service binding `ZAPI_SEC_SETTINGS`.** New > Service Binding. Name `ZAPI_SEC_SETTINGS`, package `$ZEVOLVER_SEC2F`, binding type OData V4 - Web API, service `ZAPI_SEC_SETTINGS`, binding version `0001`. Activate, then choose Publish. The binding and the service definition share the name and are different object types. The published path is `/sap/opu/odata4/sap/zapi_sec_settings/srvd_a2x/sap/zapi_sec_settings/0001/`.

**Service binding `ZAPI_SEC_ACCESS`.** Create this binding after service definition `ZAPI_SEC_ACCESS` is active. New > Service Binding. Name `ZAPI_SEC_ACCESS`, package `$ZEVOLVER_SEC2F`, binding type OData V4 - Web API, service `ZAPI_SEC_ACCESS`, binding version `0001`. Activate, then choose Publish. The published path is `/sap/opu/odata4/sap/zapi_sec_access/srvd_a2x/sap/zapi_sec_access/0001/`.

On a later pull, abapGit offers to remove the objects that are not in the repository. Keep service definition `ZAPI_SEC_ACCESS` and both bindings.

Run ABAP Unit on package `$ZEVOLVER_SEC2F`. The tests cover security classification, policy value origin, domain-text fallbacks, filter and paging, lock-flag bits, password state, and an authorization failure that does not read profile parameters or access rows. They do not read the kernel or the database.

`examples/` holds one contract sample per entity set. The values are illustrative.

## Security access extract

Read-only OData V4 service for the accounts in the logon client and for the roles and profiles assigned to them. The caller decides which accounts are in scope for an access review. The service returns the stored assignment, including a role the user received through a composite role or through HR organizational management.

Published service:

`/sap/opu/odata4/sap/zapi_sec_access/srvd_a2x/sap/zapi_sec_access/0001/`

| Entity set | Source | What a row is |
| --- | --- | --- |
| `Users` | `USR02`, `USREFUS` | One user in the logon client |
| `RoleAssignments` | `AGR_USERS` | One role on one user, with validity dates |
| `ProfileAssignments` | `UST04`, and the reference user's profiles | One profile on one user |
| `Roles` | `AGR_DEFINE`, `AGR_TEXTS` line `00000` | The role header and its first description line |
| `RoleHierarchy` | `AGR_AGRS` | One composite role and one single role |
| `RoleProfiles` | `AGR_1016` | One generated profile of one single role |

`Users` carries the user type, user group, validity, the raw `USR02-UFLAG`, the three lock bits, the password state, the password-hash version, the last logon, who created the user, the security policy, and the reference user. `SecurityPolicy` joins to `SecurityPolicies.PolicyName` on the settings service. `Client` is the logon client on every row and joins to `ClientSettings`.

The password hash is not in the extract. The person name and the email address are not in the extract. `I_User` is not a source: a normal read of that view returns no rows, and the account fields the review uses are on `USR02`.

`UserType` is `A` dialog, `B` system, `C` communications, `L` reference, or `S` service. `UserTypeText` is the domain text, with those English names when the domain text is missing.

`LockFlag` is the raw `USR02-UFLAG`. The three flags are the bits inside it: `32` globally locked by the administrator, `64` locally locked by the administrator, and `128` locked by failed logons. A stored value can combine those bits. A stray `+1` left by a maintenance lock does not change them, so `33` is still globally locked.

`PasswordState` is the stored integer. `0` can be changed and does not have to be. `1` is an initial password. `2` has expired. `3` no longer meets the current rules. `254` and `255` are the stored forms of `-2` and `-1`: the password cannot be changed, or it cannot be changed until the wait period ends. `PasswordHashVersion` is `USR02-CODVN`. `H` is the generic hash. `X` means the password is deactivated. Older codes stay on the row so the caller can see them. The hash value itself is not returned.

`ProfileSource` is `Assigned` for a row in `UST04` and `ReferenceUser` for a profile of the user named in `ReferenceUser`. The same profile can appear twice when the user has it directly and also inherits it. `RoleAssignments` already contains the single roles that came from a composite: `FromCompositeRole` is `AGR_USERS-COL_FLAG`, and `FromOrgManagement` is `AGR_USERS-ORG_FLAG`. `Excluded` is `AGR_USERS-EXCLUDE`. `RoleHierarchy` is how the caller finds which composite contains a single role. Two composites can contain the same single role.

`Roles.Description` is `AGR_TEXTS` line `00000` in the logon language. When that line is missing, the English line is used. `ParentRole` is `AGR_DEFINE-PARENT_AGR`.

`RoleProfiles` is the generated profile of a single role. `ProfileName` joins to `ProfileAssignments.ProfileName`. `RoleName` joins to `RoleAssignments.RoleName` and to `Roles.RoleName`. A profile name is 12 characters, so it is a different value from the role name. One role has one row per profile, and `Counter` keeps those rows apart. `Version` `A` is the active profile, which the user comparison writes into `UST04`. `Version` `P` is the maintenance copy. `Generated` is `X` when profile generation wrote the row. A composite role has no row. `SAP_ALL` has no row: it was not generated from a role.

### Authorization

A failed check is an OData error. The response is not an empty list. Each check requires the authorization for value `*`, so a caller who can display only some user groups or some roles does not receive a partial population.

| Entity sets | Check |
| --- | --- |
| `Users` | `S_USER_GRP` field `CLASS` = `*`, activity 03 |
| `RoleAssignments` | `S_USER_GRP` field `CLASS` = `*` activity 03, and `S_USER_AGR` field `ACT_GROUP` = `*` activity 03 |
| `ProfileAssignments` | `S_USER_GRP` field `CLASS` = `*` activity 03, and `S_USER_PRO` field `PROFILE` = `*` activity 03 |
| `Roles`, `RoleHierarchy`, `RoleProfiles` | `S_USER_AGR` field `ACT_GROUP` = `*` activity 03 |

`S_USER_AGR` stores the role name in `ACT_GROUP`. `AGR_NAME` is the column on `AGR_USERS` and `AGR_DEFINE`. SU53 lists `ACTVT` and `ACT_GROUP` for this object. Profile `SAP_ALL` grants both fields as `*`.

### Filters

The same range filters, `$select`, `$orderby`, `$top`, `$skip`, and `$count` as the settings service. A filter on an unknown property is an error (message 002 of `ZSEC_ACCESS`).

```http
GET .../Users?$filter=UserType eq 'A' and GloballyLocked eq 'X'
GET .../RoleAssignments?$filter=UserId eq 'JSMITH' and FromCompositeRole eq 'X'
GET .../ProfileAssignments?$filter=ProfileSource eq 'ReferenceUser'
GET .../Roles?$filter=ParentRole eq 'Z_FI_TEMPLATE'
GET .../RoleHierarchy?$filter=CompositeRole eq 'Z_FI_COMPOSITE'
GET .../RoleProfiles?$filter=RoleName eq 'Z_FI_DISPLAY' and Version eq 'A'
```

A read is the logon client. There is no RFC to other clients or other application servers.

### Install

The abapGit pull and the ADT objects for this service are in [Pull and activate](#pull-and-activate). The access service definition and both bindings are created in package `$ZEVOLVER_SEC2F` after the pull.

## Repositories

- Cursor: [evolver/sap-sec-extract](https://cursor.com/codebase/evolver/sap-sec-extract)
- GitHub: [aleo25672/sap-sec-extract](https://github.com/aleo25672/sap-sec-extract)

The GitHub repository is public. The Cursor remote stays `origin`. GitHub is remote `github`.
