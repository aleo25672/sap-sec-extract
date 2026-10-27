# SAP security settings extract

Read-only OData V4 service for the profile parameters shown by report RSPFPAR, plus the four settings that sit beside that report and change an IT general control conclusion: security policies, client settings, system change options, and parameter history.

The service returns raw values and, where a value is derived, the derivation. The caller compares a policy with the application server and decides whether a production client is locked.

Activate this package on S/4HANA 2025 (ABAP Platform 2025), on-premise or private cloud. It is not ABAP Cloud. `CL_SPFL_PROFILE_PARAMETER` is the class RSPFPAR uses, and it is not a released Cloud API.

The same repository contains a second service, `ZAPI_SEC_ACCESS`, for the account and assignment population. That service is documented under [Security access extract](#security-access-extract).

## Pull and activate

### Prerequisite

Pull this repository with abapGit v1.133.0 (17 February 2026) or later. v1.134.0 (10 July 2026) is the current release. From that release on, the pull publishes the service bindings. An older abapGit creates the bindings and leaves them unpublished. Open the repository list and read the version under About. Upgrade abapGit before the pull when the version is older.

Standalone abapGit is report `ZABAPGIT_STANDALONE`. Copy it, keep the copy, and run the copy for the upgrade. Pull [https://github.com/abapGit/build.git](https://github.com/abapGit/build) into a local package that already exists. The build repository contains `PROG ZABAPGIT_STANDALONE`. When that program already lives in another package, move it into the pull package (SE38, Goto, Object Directory Entry) and pull again. Activate the report. About shows v1.133.0 or later.

The report is about 37,000 lines. Loading that source through the SAP GUI editor, or pasting it into ABAP Development Tools, fails. The pull writes the report on the server. The [abapGit upgrade page](https://docs.abapgit.org/user-guide/getting-started/upgrade.html) describes an SE38 upload of `zabapgit_standalone.prog.abap`. Use that upload only when no abapGit program runs, and switch the editor to the back-end editor first (SE38, Utilities, Settings, ABAP Editor; on newer systems the label is Text-Based Editor).

The developer version is the package of classes started with transaction `ZABAPGIT`. Pull [https://github.com/abapGit/abapGit](https://github.com/abapGit/abapGit) into that package.

### Pull

One abapGit pull loads both services into package `$ZEVOLVER_SEC2F` from branch `main`. The master language is English. The package object stored in the repository is `ZSEC_SETTINGS`; this installation assigns the pulled objects to `$ZEVOLVER_SEC2F`.

1. Open abapGit (transaction `ZABAPGIT`, or report `ZABAPGIT_STANDALONE`).
2. Add the GitHub repository `https://github.com/aleo25672/sap-sec-extract.git` as an online repository, or open it if it is already linked. The same commits are on the Cursor remote `evolver/sap-sec-extract`.
3. Select branch `main`.
4. Set the package to `$ZEVOLVER_SEC2F` and the master language to English.
5. On a system where an earlier pull left `ZAPI_SEC_ACCESS` as a header with no source, delete `R3TR SRVD ZAPI_SEC_ACCESS` before pulling. Delete it in ABAP Development Tools or SE80 when the object opens. When it does not open, delete that directory entry in SE03, Change Object Directory Entries. A new system has no such object. A definition that already has its source is updated by the pull.
6. Pull, then activate the imported objects.

The interface views `ZI_SEC_USER`, `ZI_SEC_ROLE_ASSIGN`, `ZI_SEC_PROF_ASSIGN`, `ZI_SEC_ROLE`, `ZI_SEC_ROLE_HIER`, `ZI_SEC_ROLE_PROFILE`, `ZI_SEC_ROLE_AUTH`, `ZI_SEC_ROLE_ORG`, `ZI_SEC_PROFILE`, `ZI_SEC_PROF_AUTH`, `ZI_SEC_AUTH_VALUE`, `ZI_SEC_CRIT_AUTH`, and `ZI_SEC_CRIT_VAR` activate with a warning. Their tables (`USR02`, `UST04`, `AGR_USERS`, `AGR_DEFINE`, `AGR_AGRS`, `AGR_1016`, `AGR_1251`, `AGR_1252`, `USR10`, `USR11`, `UST10S`, `UST12`, `USCRAUTH`, `USCRAUTHID`, `USCRAUIDT`, `USRVARID`) are client-dependent, and the logon client is applied by the session. The warning leaves the views active.

The pull imports both service definitions. `ZAPI_SEC_ACCESS` is stored the same way as `ZAPI_SEC_SETTINGS`: a header file and the CDS source in `zapi_sec_access.srvd.srvdsrv`. abapGit writes that definition after the views and classes it exposes, which is the create that produced `ZAPI_SEC_SETTINGS`. The source is:

```cds
@EndUserText.label: 'Security access'
define service ZAPI_SEC_ACCESS {
  expose ZC_SEC_USER         as Users;
  expose ZC_SEC_ROLE_ASSIGN  as RoleAssignments;
  expose ZC_SEC_PROF_ASSIGN  as ProfileAssignments;
  expose ZC_SEC_ROLE         as Roles;
  expose ZC_SEC_ROLE_HIER    as RoleHierarchy;
  expose ZC_SEC_ROLE_PROFILE as RoleProfiles;
  expose ZC_SEC_ROLE_AUTH    as RoleAuthorizations;
  expose ZC_SEC_ROLE_ORG     as RoleOrgLevels;
  expose ZC_SEC_PROFILE      as Profiles;
  expose ZC_SEC_PROF_AUTH    as ProfileAuthorizations;
  expose ZC_SEC_AUTH_VALUE   as AuthorizationValues;
  expose ZC_SEC_CRIT_AUTH    as CriticalAuthorizations;
  expose ZC_SEC_CRIT_VAR     as CriticalAuthorizationVariants;
}
```

`Client` on these entities is a 3-character client id. `ClientSettings` keeps `abap.clnt` because there the client is the key.

The pull also imports both service bindings. Each binding is OData V4, Web API, version `0001`, and the pull publishes it. abapGit writes the binding after its service definition. The version that publishes during the pull is in [Prerequisite](#prerequisite). The published paths are:

`/sap/opu/odata4/sap/zapi_sec_settings/srvd_a2x/sap/zapi_sec_settings/0001/`

`/sap/opu/odata4/sap/zapi_sec_access/srvd_a2x/sap/zapi_sec_access/0001/`

A binding that is already published is unpublished, updated, and published again. The path stays the same. Reload `$metadata` after the pull. When `RoleProfiles` is absent from the entity container, unpublish binding `ZAPI_SEC_ACCESS` version `0001` and publish it again.

The service definitions and the bindings are in the repository, so a later pull updates them.

Run ABAP Unit on package `$ZEVOLVER_SEC2F`. The tests cover security classification, policy value origin, domain-text fallbacks, filter and paging, lock-flag bits, password state, and an authorization failure that does not read profile parameters or access rows. They do not read the kernel or the database.

`examples/` holds one contract sample per entity set. The values are illustrative.

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

RSPFPAR is the current profile of this application server. These four entity sets are the settings that report does not show. Read together, they are the evidence for two SOX IT general controls: access to programs and data, and change management. The accounts, the roles, and the profiles for that access control are the [security access extract](#security-access-extract). The test that ties a profile on a user back to the role that generated it is under [Role profiles](#role-profiles).

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

The gateway returns 100 rows in one response. `@odata.count` is the size of the filtered set when the request includes `$count=true`. `@odata.nextLink` is the following page, relative to the service root. Call that URL as the server wrote it, including `top` without a `$`. The last page has no `@odata.nextLink`. The header `Prefer: odata.maxpagesize=1683` asks for a larger page, and the response header `Preference-Applied` shows the size the server used. The same paging applies to both services.

## Security access extract

Read-only OData V4 service for the accounts in the logon client, the roles and profiles assigned to them, and the authorization values stored on those roles and profiles. The caller decides which accounts, objects, and profiles are in scope. The service returns the stored rows. It does not classify an object or a profile as critical.

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
| `RoleAuthorizations` | `AGR_1251` | One authorization field value of one role |
| `RoleOrgLevels` | `AGR_1252` | One organizational value of one role |
| `Profiles` | `USR10`, `USR11` | One profile header, active or maintenance |
| `ProfileAuthorizations` | `UST10S` | One authorization object inside one single profile |
| `AuthorizationValues` | `UST12` | One field value of one authorization |
| `CriticalAuthorizations` | `USCRAUTH`, `USCRAUTHID`, `USCRAUIDT` | One SUIM critical-authorization rule |
| `CriticalAuthorizationVariants` | `USRVARID` | One critical authorization assigned to one SUIM variant |

`Users` carries the user type, user group, validity, the raw `USR02-UFLAG`, the three lock bits, the password state, the password-hash version, the last logon, who created the user, the security policy, and the reference user. `SecurityPolicy` joins to `SecurityPolicies.PolicyName` on the settings service. `Client` is the logon client on every row and joins to `ClientSettings`.

The password hash is not in the extract. The person name and the email address are not in the extract. `I_User` is not a source: a normal read of that view returns no rows, and the account fields the review uses are on `USR02`.

`UserType` is `A` dialog, `B` system, `C` communications, `L` reference, or `S` service. `UserTypeText` is the domain text, with those English names when the domain text is missing.

`LockFlag` is the raw `USR02-UFLAG`. The three flags are the bits inside it: `32` globally locked by the administrator, `64` locally locked by the administrator, and `128` locked by failed logons. A stored value can combine those bits. A stray `+1` left by a maintenance lock does not change them, so `33` is still globally locked.

`PasswordState` is the stored integer. `0` can be changed and does not have to be. `1` is an initial password. `2` has expired. `3` no longer meets the current rules. `254` and `255` are the stored forms of `-2` and `-1`: the password cannot be changed, or it cannot be changed until the wait period ends. `PasswordHashVersion` is `USR02-CODVN`. `H` is the generic hash. `X` means the password is deactivated. Older codes stay on the row so the caller can see them. The hash value itself is not returned.

`ProfileSource` is `Assigned` for a row in `UST04` and `ReferenceUser` for a profile of the user named in `ReferenceUser`. The same profile can appear twice when the user has it directly and also inherits it. `RoleAssignments` already contains the single roles that came from a composite: `FromCompositeRole` is `AGR_USERS-COL_FLAG`, and `FromOrgManagement` is `AGR_USERS-ORG_FLAG`. `Excluded` is `AGR_USERS-EXCLUDE`. `RoleHierarchy` is how the caller finds which composite contains a single role. Two composites can contain the same single role. The same user and role can also appear on two rows when `AGR_USERS` stores two validity intervals. The entity key is `UserId` and `RoleName`, so those rows share a key, and both intervals stay in the payload.

`Roles.Description` is `AGR_TEXTS` line `00000` in the logon language. When that line is missing, the English line is used. `ParentRole` is `AGR_DEFINE-PARENT_AGR`.

`RoleProfiles` reads `AGR_1016`. `RoleName` and `Counter` are the key. `Counter` is a 6-character numeric string, such as `000001`. `ProfileName` is 12 characters. `Variant` is the profile-generator variant. `Generated` is `X` when generation wrote the row. `Version` is `AGR_1016-PSTATE`: `A` is the active profile, and `P` is the maintenance copy.

`RoleAuthorizations` is every field value stored on the role in PFCG. `Counter` is the line key. `Object`, `AuthName`, `Field`, `Low`, and `High` are the stored authorization. `AuthName` is the authorization name because `Authorization` is a reserved CDS word. `Modified`, `Deleted`, `Copied`, and `NewEntry` are the PFCG status flags. A composite role has no rows. `RoleOrgLevels` is the organizational value stored for the same role. `OrgLevel` is the organizational field, such as `$BUKRS`.

`Profiles` is the profile header. `Version` is `USR10-AKTPS`: `A` is active and `P` is the maintenance copy. `ProfileType` is `USR10-TYP`: `C` is a composite profile, `G` is a profile generated from a role, and `S` is a single profile maintained outside the profile generator. `SAP_ALL` and `SAP_NEW` are stored with the type the system gave them. The service does not add a further flag. `Description` is `USR11` in the logon language, or the English text when that language is missing. The authorization blob on `USR10` is not returned.

`ProfileAuthorizations` is `UST10S`: which authorization object and authorization name a single profile contains. `AuthorizationValues` is `UST12`: the field values of that authorization. The caller joins `Object`, `AuthName`, and `Version`. A generated profile and a single profile use the same two sets.

`CriticalAuthorizations` is the SUIM rule table `USCRAUTH`, with the color and transaction from `USCRAUTHID` and the text from `USCRAUIDT`. `SearchType` is the stored `AND` or `OR`. `CriticalGroup` is `USCRAUTH-CR_AUTH`. `CriticalAuthorizationVariants` is which rule id belongs to which variant in `USRVARID`. An empty SUIM customizing returns no rows. The service does not compare these rules with roles or profiles.

### How the caller uses the rows

The service returns every stored value. The caller chooses the objects and the profiles that matter for a review. Those names are not constants in the extract. `RoleAuthorizations` and `AuthorizationValues` are large. Request `$count=true` and `$top`, and follow `@odata.nextLink`. The service reads the whole table before it returns the page.

**Objects of interest.** Filter `RoleAuthorizations` on `Object`. The same filter on `AuthorizationValues` reads the value inside a profile. A prefix such as `S_USER_` is several object names. The caller lists the names it cares about.

```http
GET .../RoleAuthorizations?$count=true&$top=5&$filter=Object eq 'S_TCODE' and Field eq 'TCD'
GET .../RoleAuthorizations?$count=true&$top=5&$filter=Object eq 'S_DEVELOP'
GET .../RoleAuthorizations?$count=true&$top=5&$filter=Object eq 'S_USER_AGR'
GET .../RoleAuthorizations?$count=true&$top=5&$filter=Object eq 'S_TABU_DIS'
GET .../RoleAuthorizations?$count=true&$top=5&$filter=Object eq 'S_TABU_NAM'
GET .../RoleAuthorizations?$count=true&$top=5&$filter=Object eq 'S_RZL_ADM'
```

`Low` and `High` are the stored range. `AuthName` is the authorization name on that role. Join `RoleName` to `RoleAssignments.RoleName` for the accounts that have the role, and to `RoleOrgLevels.RoleName` for the organizational value. An empty `RoleOrgLevels` result means that role has no organizational level stored.

**Profiles that were not generated.** `Profiles.ProfileType` is the stored code. `G` was generated from a role and is already matched through `RoleProfiles`. `C` is a composite profile. `S` is a single profile maintained outside the profile generator. `SAP_ALL` and `SAP_NEW` are in that single-profile set when the system stored them with type `S`. Any other single profile is in the same set. Join `ProfileName` to `ProfileAssignments.ProfileName` for the accounts that have it.

```http
GET .../Profiles?$count=true&$filter=ProfileType eq 'S' and Version eq 'A'&$select=ProfileName,ProfileType,Version,Description
GET .../Profiles?$filter=ProfileName eq 'SAP_ALL' and Version eq 'A'
GET .../Profiles?$filter=ProfileName eq 'SAP_NEW' and Version eq 'A'
```

The contents of one profile are two calls. The first returns `AuthName` for an object. The second returns the field values for that name.

```http
GET .../ProfileAuthorizations?$filter=ProfileName eq 'SAP_ALL' and Version eq 'A' and Object eq 'S_TCODE'
GET .../AuthorizationValues?$filter=Object eq 'S_TCODE' and AuthName eq '<AuthName from the previous row>' and Version eq 'A'
```

A full-authorization value is `Low` `*` on field `TCD`. The same pair of calls works for `S_DEVELOP`, `S_USER_AGR`, `S_TABU_DIS`, `S_RZL_ADM`, or any other object, and for any other profile name.

**SUIM rules.** `CriticalAuthorizations` is the rule list maintained for report `RSUSR008_009_NEW`. Maintain it with transaction `SU_VCUSRVAR_CHANGE` (view cluster `VCUSRVAR`), or from `SUIM`, Users, With Critical Authorizations. Each rule is an authorization id, an object, a field, and a from/to value. `SearchType` is `AND` or `OR` for the rows of that id. `CriticalAuthorizationVariants` says which ids belong to the variant the report runs. The delivered variant `SAP_RSUSR009` is not a usable rule set. When nothing has been saved, both entity sets are empty.

The caller may use those rules as its list of objects of interest. The service does not apply them. A new object is a new row in `VCUSRVAR`, saved in a customizing request. The object name in the rule is the full name, so `S_USER_AGR` and `S_USER_GRP` are separate rows under one id, linked with `OR`. An asterisk in the from-value means full authorization for that field. A stored asterisk is entered as `#*`.

```http
GET .../CriticalAuthorizations?$count=true&$top=20
GET .../CriticalAuthorizationVariants?$count=true
GET .../RoleAuthorizations?$count=true&$top=5&$filter=Object eq '<Object from a CriticalAuthorizations row>'
```

### Access to programs and data

A reviewer authorizes roles. The kernel checks profiles. A generated profile is the collection of authorizations of one single role. The profile name is 12 characters and the role name is 30, so `RoleProfiles` is the match between them. The service returns the populations. The caller applies the test.

| Population | Entity sets | Control question |
| --- | --- | --- |
| Accounts and their roles | `Users`, `RoleAssignments`, `RoleHierarchy` | Which roles does this account have, including a role received through a composite or through organizational management? |
| Profiles on the account | `ProfileAssignments` | Which profiles will the kernel check, including a profile typed directly on the user and a profile inherited from a reference user? |
| Generated profile of a single role | `RoleProfiles` | Was each of those profiles generated by a role the account still has? |
| Values inside a role or a profile | `RoleAuthorizations`, `RoleOrgLevels`, `Profiles`, `ProfileAuthorizations`, `AuthorizationValues` | Which authorization objects and values are stored, and which profiles were not generated from a role? |
| SUIM rules | `CriticalAuthorizations`, `CriticalAuthorizationVariants` | Which object, field, and value rules are maintained for report `RSUSR008_009_NEW`? |

`RoleAssignments` is the review population. `ValidFrom` and `ValidTo` are the interval stored on `AGR_USERS`. `Excluded` means the role was removed from the composite for this user. `FromCompositeRole` means the single role arrived through a composite, and `RoleHierarchy` names that composite. `FromOrgManagement` means HR organizational management assigned the role. `Users.SecurityPolicy` joins to `SecurityPolicies.PolicyName` on the settings service for the password and logon rules that apply to the account.

`ProfileAssignments` is what the check uses. `ProfileSource` `Assigned` is stored on the user in `UST04`. `ProfileSource` `ReferenceUser` is a profile of `Users.ReferenceUser`. The dialog account does not hold that profile in its own `UST04`, and the service does not copy the reference user's roles onto the dialog account. `SAP_ALL` is a profile in this set.

### Role profiles

Keep `RoleProfiles` rows with `Version` `A`. User comparison, transaction PFUD, writes that active profile into `UST04`. `Version` `P` is the copy still open in PFCG. A composite role has no `AGR_1016` row. The single roles inside it do. `SAP_ALL` has no row, because it was not generated from a role.

For each `ProfileAssignments` row with `ProfileSource` `Assigned`:

1. Join `ProfileName` to `RoleProfiles.ProfileName` where `Version` is `A`.
2. Join that `RoleName` to `RoleAssignments.RoleName` for the same `UserId`.

A profile that finds both rows was generated by a role the user still has. When `FromCompositeRole` is `X`, `RoleHierarchy` names the composite the reviewer authorized.

A profile that finds no active `RoleProfiles` row has no generating role left in PFCG. `SAP_ALL`, a profile typed on the user in SU01, and a profile whose role has been deleted from the system are in this group.

A profile that finds a role in `RoleProfiles` and finds no `RoleAssignments` row for that user remained in `UST04` after the role was removed. User comparison did not delete it.

A `RoleAssignments` row whose active `RoleProfiles` profile is missing from `ProfileAssignments` for that user is the opposite gap. The role is assigned, and user comparison has not copied the generated profile into the user master.

`Version` `P` without a current `Version` `A` row for the same role means the role was changed in PFCG and the profile has not been generated again.

A reference-user profile uses the same two joins against the reference user's own `RoleAssignments`. The profile is inherited. The role is not.

### Authorization

A failed check is an OData error. The response is not an empty list. Each check requires the authorization for value `*`, so a caller who can display only some user groups or some roles does not receive a partial population.

| Entity sets | Check |
| --- | --- |
| `Users` | `S_USER_GRP` field `CLASS` = `*`, activity 03 |
| `RoleAssignments` | `S_USER_GRP` field `CLASS` = `*` activity 03, and `S_USER_AGR` field `ACT_GROUP` = `*` activity 03 |
| `ProfileAssignments` | `S_USER_GRP` field `CLASS` = `*` activity 03, and `S_USER_PRO` field `PROFILE` = `*` activity 03 |
| `Roles`, `RoleHierarchy`, `RoleProfiles`, `RoleAuthorizations`, `RoleOrgLevels`, `CriticalAuthorizations`, `CriticalAuthorizationVariants` | `S_USER_AGR` field `ACT_GROUP` = `*` activity 03 |
| `Profiles`, `ProfileAuthorizations`, `AuthorizationValues` | `S_USER_PRO` field `PROFILE` = `*` activity 03 |

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
GET .../RoleAuthorizations?$filter=Object eq 'S_TCODE' and Low eq 'FB03'
GET .../Profiles?$filter=ProfileType eq 'S' and Version eq 'A'
GET .../ProfileAuthorizations?$filter=ProfileName eq 'SAP_ALL'
GET .../AuthorizationValues?$filter=Object eq 'S_TCODE' and AuthName eq '&_SAP_ALL'
GET .../CriticalAuthorizations?$filter=AuthorizationId eq 'ZTCD'
```

A read is the logon client. There is no RFC to other clients or other application servers.

### Install

The abapGit pull for this service is in [Pull and activate](#pull-and-activate). The pull imports service definition `ZAPI_SEC_ACCESS` and binding `ZAPI_SEC_ACCESS`, and it publishes the binding.

## Repositories

- Cursor: [evolver/sap-sec-extract](https://cursor.com/codebase/evolver/sap-sec-extract)
- GitHub: [aleo25672/sap-sec-extract](https://github.com/aleo25672/sap-sec-extract)

The GitHub repository is public. The Cursor remote stays `origin`. GitHub is remote `github`.
