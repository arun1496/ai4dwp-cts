# Step-by-Step: Create Azure Virtual Desktop from Scratch

This is a practical, simple sequence for building AVD in Azure with one pooled host.

## Step 0: Prepare

You need:
- Azure CLI installed
- Logged in to Azure with a role that can create resources and role assignments (Owner or User Access Administrator + Contributor combo)
- Target subscription ID
- Region
- Resource naming standard

## Step 1: Validate identity and permission

1. Check active account and subscription.
2. Check your RBAC role on subscription/resource group scope.
3. Confirm you can create role assignments before starting user access steps.

## Step 2: Create resource group and networking

1. Create resource group in target region.
2. Create VNet and subnet for session hosts.
3. Confirm subnet ID.

## Step 3: Create AVD control plane

1. Create host pool:
- Type: Pooled
- Load balancing: BreadthFirst
- Max sessions per host: 5

2. Create workspace.
3. Create desktop application group.
4. Register application group to workspace.
5. Verify host pool/workspace/app group objects.

## Step 4: Create session host VM

1. Select a valid Windows 11 multi-session AVD image available in your region.
2. Create VM with:
- Size: Standard_B2ms
- Security type: TrustedLaunch
- Secure Boot: enabled
- vTPM: enabled
- Attached to AVD subnet

3. Add AADLoginForWindows extension.

## Step 5: Register VM to host pool

1. Retrieve host pool registration token.
2. Install/trigger AVD registration agent (DSC AddSessionHost method is common).
3. Confirm VM extensions complete successfully.

## Step 6: Assign user access

1. Assign Virtual Machine User Login on VM scope for direct VM sign-in.
2. Assign Desktop Virtualization User on application group scope for AVD client desktop access.
3. Verify both assignments.

## Step 7: Validate health end to end

1. Check session host status from ARM sessionHosts endpoint.
2. Validate heartbeat and health checks.
3. Confirm host status is Available.
4. Validate app group registration and workspace mapping.

## Step 8: If host is not healthy, troubleshoot in this order

1. VM extension status (AADLoginForWindows, DSC).
2. Session host health checks from ARM (DomainJoinedCheck, DomainTrustCheck, AADJoinedHealthCheck).
3. dsregcmd /status from VM run-command.
4. AVD agent service status and event logs from run-command.
5. Correct issue and re-check status; do not blindly rerun create commands.

## Minimum acceptance checklist

- Host pool exists and has correct settings.
- Workspace exists and app group is registered.
- VM exists with requested image/size/security.
- User RBAC assignments exist at both required scopes.
- Session host shows Available with recent heartbeat.

