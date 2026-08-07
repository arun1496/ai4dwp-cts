# L2/L3 Knowledge Base: AVD Black Screen – DWM Crash Loop (Intel Driver Regression)

**Version:** v1.0  
**Date:** 07/08/2026  
**Status:** Draft  
**Audience:** L2/L3 Infrastructure Engineers, Platform Operations  
**Related Pools:** POOL-FIN-01, POOL-FIN-02  

---

## Background

### What the System Does

Azure Virtual Desktop (AVD) host pools are managed collections of session host VMs running Windows Server with the Remote Desktop Services role. Users connect via the AVD client, establish an RDP session, and interact with a desktop environment hosted on a session host. The session host provisioning and configuration is orchestrated through Azure Compute Galleries that store versioned base images; when a new image version is released, host pool configuration references that version, and scale-set or manual reimage operations rebuild session hosts to the new image.

**POOL-FIN-01** and **POOL-FIN-02** are paired host pools serving the Finance business unit. They use identical base images published to a shared Azure Compute Gallery. During normal operations, both pools are maintained on the same image version to ensure consistency; however, image updates are deployed via staged rollout: POOL-FIN-01 receives the update first, is validated for stability, and only then is POOL-FIN-02 updated.

### Why It Matters

The Desktop Window Manager (DWM) is a critical Windows display compositor that runs in Session 0 on each session host. DWM is responsible for rendering the visual desktop, window compositing, and direct display output. If DWM crashes during or immediately after user session initialisation, the user receives a black screen, the session disconnects within seconds, and the user is forced to reconnect. For Finance users operating time-sensitive applications (trading, settlement, reconciliation), even a 3-hour disruption causing recurring black screens and reconnect loops translates to operational downtime, lost productivity, and compliance/audit risk.

The Intel graphics driver components (particularly igdumd64.dll in this case) are kernel-mode and user-mode drivers that interface between DWM, the OS graphics subsystem, and the virtual GPU layer in Azure. A driver regression – an incompatible or defective version – introduced into the host image can break DWM initialisation at the exact moment a user's session starts, triggering the crash-loop pattern described below.

---

## Symptom

### What the Engineer Observes

1. **User reports:** Users report that when they log into POOL-FIN-01 via the AVD client, the desktop appears briefly (1–2 seconds) then goes black, and the session disconnects within 2–6 seconds.

2. **Reconnect loop:** Some users report the session auto-reconnects immediately after the disconnect. They log in again and experience the same black screen and disconnect. This repeats 2–4 times before the user reports the issue or the session finally stays connected (after a variable delay, sometimes on the 3rd or 4th reconnect).

3. **Scale of impact:** The issue is not isolated to one user or one host—reports come from multiple Finance team members on the same day, suggesting a systemic failure affecting a significant portion of the POOL-FIN-01 pool capacity.

4. **Incident trigger timing:** The problem appears suddenly within minutes of a known infrastructure change (e.g., an overnight image update, driver update, or host reboot).

5. **Pool comparison:** Users connecting to POOL-FIN-02 do NOT experience black screen or disconnection. Only POOL-FIN-01 is affected.

### What the User Reports (to Service Desk)

- "I cannot log into Finance [system name]. I get a black screen as soon as I connect to my desktop."
- "My session keeps disconnecting and reconnecting when I try to open my Finance VDI."
- "The black screen has been happening for [3 hours]. Other team members have the same problem."

---

## Root Cause

### Technical Cause (Confirmed)

An overnight image update deployed to POOL-FIN-01 at 2026-08-06 02:00 introduced an incompatible or defective version of the Intel graphics driver component **igdumd64.dll** (User-mode Intel Graphics Driver, 64-bit). When a user successfully logs onto a POOL-FIN-01 session host, the Remote Desktop Services logon process launches the user's desktop session and initialises DWM. DWM immediately loads igdumd64.dll to handle display compositing for the virtual GPU. The defective driver version throws a memory access violation (exception code **0xc0000005**, "Access Violation") when DWM attempts to initialise graphics rendering. DWM crashes within 2–6 seconds of the session logon event. The crashed DWM process triggers the TerminalServices session disconnect (Event 40) to fire, terminating the user's RDP session. The user's AVD client then auto-reconnects, and the cycle repeats.

**Crash sequence (observable in event logs):**

Event 21 (TerminalServices-LocalSessionManager logon succeeded) → +2–6 seconds → Event 1000 (Application Error: dwm.exe in igdumd64.dll, exception 0xc0000005) → Event 40 (TerminalServices-LocalSessionManager session disconnected) → Event 9009 (Desktop Window Manager exit with code 0x40010004) → +10–20 seconds → auto-reconnect (Event 21 repeats).

### Evidence That Confirms Root Cause

1. **Affected vs. Unaffected Pool Comparison:**
   - **POOL-FIN-01** (updated at 02:00): All session hosts exhibit the crash-disconnect-reconnect loop.
   - **POOL-FIN-02** (NOT updated): Logon succeeds cleanly, DWM initialises successfully (Event 9011 observed), no Event 1000 crash for dwm.exe, no Event 40 disconnects, no Event 9009 DWM exits.
   - **Differentiating variable:** Image version. Both pools use identical configuration and VLAN; only POOL-FIN-01 received the overnight update.

2. **Repeated Crash Signature Across Multiple Users:**
   - User FINBRIDGE\mlopez logged on at 07:02:10; Event 1000 (dwm.exe + igdumd64.dll) occurred at 07:02:16.
   - User FINBRIDGE\akapoor logged on at 07:08:22; identical Event 1000 (dwm.exe + igdumd64.dll) occurred at 07:08:24.
   - Crash signature is identical across different users, ruling out user-state (profile/FSLogix) or user-specific policy causes.

3. **Crash Timing Relative to Session Lifecycle:**
   - Event 21 (logon succeeded) fires first, indicating Remote Desktop Services logon completed successfully.
   - Event 1000 (crash) fires 2–6 seconds later, during the shell/desktop initialisation phase, specifically when DWM loads the graphics driver.
   - Crash does NOT occur during logon or authentication phases; it occurs during desktop rendering.
   - This pinpoints the faulting module to the graphics rendering path, not the logon/authentication path.

4. **Specific Faulting Module Across All Crashes:**
   - Every Event 1000 on affected hosts names the same faulting module: **igdumd64.dll**.
   - File version of igdumd64.dll on affected hosts is newer (updated) compared to POOL-FIN-02.
   - On unaffected POOL-FIN-02, DWM starts cleanly (Event 9011 observed) with no corresponding Event 1000.

5. **Host Reboot Timing:**
   - Event 1 (Kernel-General) on affected POOL-FIN-01 hosts shows boot time 02:03:11, confirming hosts rebooted into the new image 3 minutes after the update was applied at 02:00.
   - POOL-FIN-02 hosts show an older boot time, confirming they did not reboot and retained the prior image version.

---

## Detection

### How to Confirm This is the Issue (Before Acting)

**Prerequisites:**
- Access to Azure Portal with permissions to view Virtual Machines and AVD Host Pools.
- Local Administrator rights or Remote Desktop access to at least one affected session host.
- PowerShell execution capability on a session host (via Azure Run Command or RDP).

**Detection procedure:**

### Step 1: Identify Affected Pool and Hosts

**Action:** In Azure Portal, navigate to **Azure Virtual Desktop → Host pools → POOL-FIN-01 → Session hosts**.

**Expected result:** You see a list of session host VMs (e.g., SHFIN-01-A, SHFIN-01-B, SHFIN-01-C, etc.).

**What to look for:** 
- Note the current image version shown in the **Image** column for each host.
- Confirm all POOL-FIN-01 hosts are on the same image version.
- Record this version string (e.g., "FIN-20260806-1") for later comparison.

**Note:** If you see mixed image versions on POOL-FIN-01, this is a separate issue (partial rollout failure); halt and escalate.

---

### Step 2: Confirm POOL-FIN-02 is Unaffected

**Action:** Navigate to **Azure Virtual Desktop → Host pools → POOL-FIN-02 → Session hosts**.

**Expected result:** You see session hosts for POOL-FIN-02 (e.g., SHFIN-02-A, SHFIN-02-B, etc.).

**What to look for:**
- Image version in the **Image** column should be OLDER than POOL-FIN-01's current version.
- Example: POOL-FIN-02 shows "FIN-20260730-2", POOL-FIN-01 shows "FIN-20260806-1".
- Confirm there are no user reports of black screen or disconnects from POOL-FIN-02 users in the same timeframe.

**Comparison finding:** If POOL-FIN-02 is on a newer image than POOL-FIN-01, this is not a DWM driver regression; investigate a different root cause.

---

### Step 3: Examine Application Event Log on Affected Host

**Action:** Open Azure Portal → **Virtual Machines → SHFIN-01-A → Operations → Run command → RunPowerShellScript**.

**Command to run:**
```powershell
$start = (Get-Date).AddHours(-4)

Get-WinEvent -FilterHashtable @{ LogName='Application'; Id=1000; StartTime=$start } |
  Where-Object { $_.Message -match 'dwm.exe' -and $_.Message -match 'igdumd64.dll' } |
  Select-Object TimeCreated, Id, ProviderName, Message |
  Format-List

Get-WinEvent -FilterHashtable @{ LogName='System'; Id=9009; StartTime=$start } |
  Select-Object TimeCreated, Id, ProviderName, Message |
  Format-List
```

**Healthy control host (POOL-FIN-02): check System log Event 9011**

```powershell
$start = (Get-Date).AddHours(-4)

Get-WinEvent -FilterHashtable @{ LogName='System'; Id=9011; StartTime=$start } |
  Select-Object TimeCreated, Id, ProviderName, Message |
  Format-List
```

**What confirms this issue:**
- In the **Application log**, you find **Event 1000** for `dwm.exe` and the faulting module is explicitly **igdumd64.dll**.
- On the same affected host, you also find **Event 9009** in the **System log** from Desktop Window Manager, usually within 1 to 2 seconds of the Event 1000 entry.
- On the unaffected control host in **POOL-FIN-02**, you find **Event 9011** in the **System log**, showing DWM started normally.

**Fast interpretation:**
- **Confirmed:** POOL-FIN-01 shows **Event 1000** in the **Application log** naming **igdumd64.dll**, and matching **Event 9009** in the **System log**; POOL-FIN-02 shows **Event 9011** as the healthy baseline.
- **Not this issue:** No **Event 1000** in the **Application log**, no **Event 9009** on the affected host, or no **Event 9011** on the POOL-FIN-02 control host.

### Detection Summary Checklist

| Check | Expected Finding | Confirmation |
|---|---|---|
| Exact Application log location used | `Event Viewer -> Windows Logs -> Application` | ✓ |
| Event 1000 on affected POOL-FIN-01 host | `dwm.exe` crash present | ✓ |
| Faulting module in Event 1000 | `igdumd64.dll` named explicitly | ✓ |
| Event 9009 on affected POOL-FIN-01 host | Desktop Window Manager exit present | ✓ |
| Healthy control baseline | Event 9011 present on POOL-FIN-02 | ✓ |

If all checks return "✓", **this is a DWM driver regression** and you should proceed to Resolution.

---

## Resolution

### 5-10 Minute Operator Runbook

Use the CLI path first. Use the portal only when you need to visually confirm the exact blade or option.

**Exact Azure Portal paths used in this section:**
- **Drain or re-enable a host:** Azure Portal -> **Azure Virtual Desktop** -> **Host pools** -> **POOL-FIN-01** -> **Session hosts** -> select host -> **Allow new sessions**.
- **Check fallback capacity:** Azure Portal -> **Azure Virtual Desktop** -> **Host pools** -> **POOL-FIN-02** -> **Session hosts** -> review **Status**, **Sessions**, and **Allow new sessions**.
- **Change the host-pool image setting:** Azure Portal -> **Azure Virtual Desktop** -> **Host pools** -> **POOL-FIN-01** -> **Session host configuration** -> **Virtual machines** -> **Image**.
- **Reimage a host:** Azure Portal -> **Virtual Machines** -> **SHFIN-01-A** -> **Overview** -> **Reimage**.
- **Run validation commands on a host:** Azure Portal -> **Virtual Machines** -> **SHFIN-01-A** -> **Operations** -> **Run command** -> **RunPowerShellScript**.

**CLI prerequisites:**
```powershell
az extension add --name desktopvirtualization

$sub = '<subscription-id>'
$rg = '<resource-group>'
$vmRg = '<vm-resource-group>'
$hostPool = 'POOL-FIN-01'
$controlPool = 'POOL-FIN-02'
$canary = 'SHFIN-01-A'
$affectedHosts = @('SHFIN-01-A','SHFIN-01-B','SHFIN-01-C')
$knownGoodTemplate = '.\pool-fin-01-known-good-vmtemplate.json'
az account set --subscription $sub
```

### Step 1: Drain POOL-FIN-01

**Portal path:** Azure Portal -> **Azure Virtual Desktop** -> **Host pools** -> **POOL-FIN-01** -> **Session hosts** -> select each affected host -> **Allow new sessions = Off** -> **Save**.

**Azure CLI:**
```powershell
foreach ($host in $affectedHosts) {
  az resource update `
    --ids "/subscriptions/$sub/resourceGroups/$rg/providers/Microsoft.DesktopVirtualization/hostPools/$hostPool/sessionHosts/$host" `
    --set properties.allowNewSession=false `
    --only-show-errors
}
```

**Expected result:** In **Azure Virtual Desktop -> Host pools -> POOL-FIN-01 -> Session hosts**, the **Allow new sessions** column shows **No** for each drained host.

### Step 2: Confirm POOL-FIN-02 Has Capacity

**Portal path:** Azure Portal -> **Azure Virtual Desktop** -> **Host pools** -> **POOL-FIN-02** -> **Session hosts**.

**What to look for:** At least one host shows **Status = Available** and **Allow new sessions = Yes**.

### Step 3: Put the Known-Good Image on POOL-FIN-01

**Portal path:** Azure Portal -> **Azure Virtual Desktop** -> **Host pools** -> **POOL-FIN-01** -> **Session host configuration** -> **Virtual machines** -> **Image**.

**What to change:** Select the same gallery image version currently used by the healthy control pool, **POOL-FIN-02**.

**Azure CLI:**
```powershell
az desktopvirtualization hostpool show `
  --resource-group $rg `
  --name $hostPool `
  --query vmTemplate `
  --output tsv > current-vmtemplate.json

# Copy current-vmtemplate.json to pool-fin-01-known-good-vmtemplate.json
# Edit only the image reference fields so they point to the known-good gallery image version.

az desktopvirtualization hostpool update `
  --resource-group $rg `
  --name $hostPool `
  --vm-template "@$knownGoodTemplate" `
  --only-show-errors
```

**Expected result:** In **Azure Virtual Desktop -> Host pools -> POOL-FIN-01 -> Session host configuration -> Virtual machines -> Image**, the image now shows the known-good version.

### Step 4: Reimage the Canary Host

**Portal path:** Azure Portal -> **Virtual Machines** -> **SHFIN-01-A** -> **Overview** -> **Reimage**.

**Azure CLI:**
```powershell
az vm reimage --resource-group $vmRg --name $canary --no-wait --only-show-errors
az vm wait --resource-group $vmRg --name $canary --updated --only-show-errors
```

**Expected result:** In **Virtual Machines -> SHFIN-01-A -> Overview**, **Provisioning state = Succeeded** and **Power state = Running**.

### Step 5: Validate the Canary Host

**Portal paths:**
- Azure Portal -> **Virtual Machines** -> **SHFIN-01-A** -> **Overview**
- Azure Portal -> **Virtual Machines** -> **SHFIN-01-A** -> **Operations** -> **Run command** -> **RunPowerShellScript**

**Azure CLI:**
```powershell
az vm run-command invoke `
  --resource-group $vmRg `
  --name $canary `
  --command-id RunPowerShellScript `
  --scripts "Get-Item 'C:\Windows\System32\igdumd64.dll' | Select-Object -ExpandProperty VersionInfo | Select-Object FileVersion; Get-WinEvent -FilterHashtable @{LogName='Application';Id=1000;StartTime=(Get-Date).AddMinutes(-15)} | Where-Object { $_.Message -match 'dwm.exe' -or $_.Message -match 'igdumd64.dll' } | Measure-Object; Get-WinEvent -FilterHashtable @{LogName='System';Id=9009;StartTime=(Get-Date).AddMinutes(-15)} | Measure-Object" `
  --query "value[0].message" `
  --output tsv
```

**Healthy result:**
- `igdumd64.dll` shows the known-good file version.
- Event 1000 count is `0` in the last 15 minutes.
- Event 9009 count is `0` in the last 15 minutes.

### Step 6: Re-enable the Canary and Test One Login

**Portal path:** Azure Portal -> **Azure Virtual Desktop** -> **Host pools** -> **POOL-FIN-01** -> **Session hosts** -> **SHFIN-01-A** -> **Allow new sessions = On** -> **Save**.

**Azure CLI:**
```powershell
az resource update `
  --ids "/subscriptions/$sub/resourceGroups/$rg/providers/Microsoft.DesktopVirtualization/hostPools/$hostPool/sessionHosts/$canary" `
  --set properties.allowNewSession=true `
  --only-show-errors
```

**Expected result:** The user reaches desktop normally and remains connected for at least 2 minutes.

### Step 7: Reimage Remaining Hosts in Small Batches

**Portal paths:**
- Drain: Azure Portal -> **Azure Virtual Desktop** -> **Host pools** -> **POOL-FIN-01** -> **Session hosts** -> host -> **Allow new sessions = Off**
- Reimage: Azure Portal -> **Virtual Machines** -> host -> **Overview** -> **Reimage**
- Re-enable: Azure Portal -> **Azure Virtual Desktop** -> **Host pools** -> **POOL-FIN-01** -> **Session hosts** -> host -> **Allow new sessions = On**

**Azure CLI:**
```powershell
$batch = @('SHFIN-01-B','SHFIN-01-C')

foreach ($host in $batch) {
  az resource update --ids "/subscriptions/$sub/resourceGroups/$rg/providers/Microsoft.DesktopVirtualization/hostPools/$hostPool/sessionHosts/$host" --set properties.allowNewSession=false --only-show-errors
  az vm reimage --resource-group $vmRg --name $host --no-wait --only-show-errors
}

foreach ($host in $batch) {
  az vm wait --resource-group $vmRg --name $host --updated --only-show-errors
  az resource update --ids "/subscriptions/$sub/resourceGroups/$rg/providers/Microsoft.DesktopVirtualization/hostPools/$hostPool/sessionHosts/$host" --set properties.allowNewSession=true --only-show-errors
}
```

**Expected result:** Each host returns to **Running**, shows **Allow new sessions = Yes**, and no new Event 1000 or 9009 entries appear after test logons.

---

## Verification

### Fast Verification

**Exact Azure Portal paths used in this section:**
- **Pool state:** Azure Portal -> **Azure Virtual Desktop** -> **Host pools** -> **POOL-FIN-01** -> **Session hosts**.
- **Configured image:** Azure Portal -> **Azure Virtual Desktop** -> **Host pools** -> **POOL-FIN-01** -> **Session host configuration** -> **Virtual machines** -> **Image**.
- **Host event checks:** Azure Portal -> **Virtual Machines** -> host -> **Operations** -> **Run command** -> **RunPowerShellScript**.

### Verification Step 1: Confirm the Host Pool Image Setting

**Portal path:** Azure Portal -> **Azure Virtual Desktop** -> **Host pools** -> **POOL-FIN-01** -> **Session host configuration** -> **Virtual machines** -> **Image**.

**Azure CLI:**
```powershell
az desktopvirtualization hostpool show `
  --resource-group $rg `
  --name $hostPool `
  --query vmTemplate `
  --output jsonc
```

**Pass condition:** The configured image in **POOL-FIN-01** matches the known-good image version used for recovery.

### Verification Step 2: Confirm Hosts Are Enabled and Healthy

**Portal path:** Azure Portal -> **Azure Virtual Desktop** -> **Host pools** -> **POOL-FIN-01** -> **Session hosts**.

**What to confirm in the grid:**
- **Status = Available** or healthy equivalent.
- **Allow new sessions = Yes**.
- **Sessions** is stable and not repeatedly dropping.

**Azure CLI:**
```powershell
foreach ($host in $affectedHosts) {
  az resource show `
    --ids "/subscriptions/$sub/resourceGroups/$rg/providers/Microsoft.DesktopVirtualization/hostPools/$hostPool/sessionHosts/$host" `
    --query "{host:name,allowNewSession:properties.allowNewSession,status:properties.status}" `
    --output table
}
```

### Verification Step 3: Confirm Event Logs Stay Clean

**Portal path:** Azure Portal -> **Virtual Machines** -> host -> **Operations** -> **Run command** -> **RunPowerShellScript**.

**Azure CLI:**
```powershell
foreach ($host in $affectedHosts) {
  az vm run-command invoke `
    --resource-group $vmRg `
    --name $host `
    --command-id RunPowerShellScript `
    --scripts "$a=(Get-WinEvent -FilterHashtable @{LogName='Application';Id=1000;StartTime=(Get-Date).AddMinutes(-30)} | Where-Object { $_.Message -match 'dwm.exe' -or $_.Message -match 'igdumd64.dll' } | Measure-Object).Count; $b=(Get-WinEvent -FilterHashtable @{LogName='System';Id=9009;StartTime=(Get-Date).AddMinutes(-30)} | Measure-Object).Count; $c=(Get-WinEvent -FilterHashtable @{LogName='System';ProviderName='TerminalServices-LocalSessionManager';Id=40;StartTime=(Get-Date).AddMinutes(-30)} | Measure-Object).Count; Write-Host \"$env:COMPUTERNAME Event1000=$a Event9009=$b Event40=$c\"" `
    --query "value[0].message" `
    --output tsv
}
```

**Pass condition:** Each host reports `Event1000=0`, `Event9009=0`, and `Event40=0` for the last 30 minutes.

### Verification Step 4: Confirm User Test Login

**Portal path:** Azure Portal -> **Azure Virtual Desktop** -> **Host pools** -> **POOL-FIN-01** -> **Session hosts**.

**Pass condition:** A test user connects to **POOL-FIN-01**, gets desktop within 30 seconds, and stays connected for 2 minutes without a black screen or reconnect loop.

---

## Rollback

### Fast Rollback

Use rollback immediately if the canary still shows black screen behavior, Event 1000 reappears, Event 9009 reappears, or the login loop returns.

**Exact Azure Portal paths used in this section:**
- **Drain hosts:** Azure Portal -> **Azure Virtual Desktop** -> **Host pools** -> **POOL-FIN-01** -> **Session hosts** -> host -> **Allow new sessions = Off**.
- **Enable fallback pool:** Azure Portal -> **Azure Virtual Desktop** -> **Host pools** -> **POOL-FIN-02** -> **Session hosts** -> host -> **Allow new sessions = On**.
- **Restore previous image setting:** Azure Portal -> **Azure Virtual Desktop** -> **Host pools** -> **POOL-FIN-01** -> **Session host configuration** -> **Virtual machines** -> **Image**.
- **Reimage rollback canary:** Azure Portal -> **Virtual Machines** -> **SHFIN-01-A** -> **Overview** -> **Reimage**.

### Rollback Step 1: Drain POOL-FIN-01 Again

**Azure CLI:**
```powershell
foreach ($host in $affectedHosts) {
  az resource update `
    --ids "/subscriptions/$sub/resourceGroups/$rg/providers/Microsoft.DesktopVirtualization/hostPools/$hostPool/sessionHosts/$host" `
    --set properties.allowNewSession=false `
    --only-show-errors
}
```

### Rollback Step 2: Keep POOL-FIN-02 Open for Users

**Portal path:** Azure Portal -> **Azure Virtual Desktop** -> **Host pools** -> **POOL-FIN-02** -> **Session hosts** -> confirm at least one host has **Allow new sessions = On**.

### Rollback Step 3: Restore the Previous Known-Good Image

**Portal path:** Azure Portal -> **Azure Virtual Desktop** -> **Host pools** -> **POOL-FIN-01** -> **Session host configuration** -> **Virtual machines** -> **Image**.

**Azure CLI:**
```powershell
$rollbackTemplate = '.\pool-fin-01-previous-good-vmtemplate.json'

az desktopvirtualization hostpool update `
  --resource-group $rg `
  --name $hostPool `
  --vm-template "@$rollbackTemplate" `
  --only-show-errors
```

### Rollback Step 4: Reimage the Canary on the Restored Image

**Azure CLI:**
```powershell
az vm reimage --resource-group $vmRg --name $canary --no-wait --only-show-errors
az vm wait --resource-group $vmRg --name $canary --updated --only-show-errors
```

### Rollback Step 5: Validate the Rollback Canary

**Portal paths:**
- Azure Portal -> **Virtual Machines** -> **SHFIN-01-A** -> **Operations** -> **Run command** -> **RunPowerShellScript**
- Azure Portal -> **Azure Virtual Desktop** -> **Host pools** -> **POOL-FIN-01** -> **Session hosts** -> **SHFIN-01-A** -> **Allow new sessions = On**

**Azure CLI:**
```powershell
az resource update `
  --ids "/subscriptions/$sub/resourceGroups/$rg/providers/Microsoft.DesktopVirtualization/hostPools/$hostPool/sessionHosts/$canary" `
  --set properties.allowNewSession=true `
  --only-show-errors

az vm run-command invoke `
  --resource-group $vmRg `
  --name $canary `
  --command-id RunPowerShellScript `
  --scripts "$a=(Get-WinEvent -FilterHashtable @{LogName='Application';Id=1000;StartTime=(Get-Date).AddMinutes(-15)} | Where-Object { $_.Message -match 'dwm.exe' -or $_.Message -match 'igdumd64.dll' } | Measure-Object).Count; $b=(Get-WinEvent -FilterHashtable @{LogName='System';Id=9009;StartTime=(Get-Date).AddMinutes(-15)} | Measure-Object).Count; Write-Host \"Event1000=$a Event9009=$b\"" `
  --query "value[0].message" `
  --output tsv
```

**Pass condition:** `Event1000=0` and `Event9009=0`, and a test user gets a stable desktop.

### Rollback Step 6: Reimage Remaining Hosts on the Restored Image

**Azure CLI:**
```powershell
$rollbackBatch = @('SHFIN-01-B','SHFIN-01-C')

foreach ($host in $rollbackBatch) {
  az resource update --ids "/subscriptions/$sub/resourceGroups/$rg/providers/Microsoft.DesktopVirtualization/hostPools/$hostPool/sessionHosts/$host" --set properties.allowNewSession=false --only-show-errors
  az vm reimage --resource-group $vmRg --name $host --no-wait --only-show-errors
}

foreach ($host in $rollbackBatch) {
  az vm wait --resource-group $vmRg --name $host --updated --only-show-errors
  az resource update --ids "/subscriptions/$sub/resourceGroups/$rg/providers/Microsoft.DesktopVirtualization/hostPools/$hostPool/sessionHosts/$host" --set properties.allowNewSession=true --only-show-errors
}
```

**Expected result:** In **Azure Virtual Desktop -> Host pools -> POOL-FIN-01 -> Session hosts**, each recovered host shows **Allow new sessions = Yes** and stable status.

---

## Preventive

### The Specific Changes to Process or Tooling That Stop This Recurring

The root cause analysis identified that the image acceptance and release pipeline lacked DWM and graphics driver validation. Below are specific, actionable preventive measures that address the gap:

---

### Preventive Action 1: Add DWM Stability to Image Acceptance Criteria

**What:** Modify the image release checklist to include a mandatory post-login DWM initialisation check.

**Specific change:** 

In your image build and release documentation (e.g., "AVD Image Release Checklist" or "Image Acceptance Criteria"), add a new section:

```
SECTION: Desktop Window Manager (DWM) Stability
Requirement: After candidate image is built, perform a test session logon.
  1. Log in as a test user to a host running the candidate image.
  2. Capture Windows event logs from the host.
  3. Verify the following:
     - Event 9011 (Desktop Window Manager) appears, indicating DWM started successfully.
     - NO Event 1000 entries mentioning dwm.exe or igdumd64.dll.
     - NO Event 9009 entries (DWM exits).
  4. If any of the above checks fail, REJECT the candidate image.
     Mark as "Failed DWM stability check" and return to image engineering.
Acceptance criteria: PASS (all checks pass) or REJECT.
Owner: Image Engineering Team
Timing: Must complete before any production image deployment.
```

**Owner:** Image Engineering Team

**Timeline:** Implement before the next scheduled image release (typically within 1 sprint).

**Evidence:** Checklist item added to internal image release documentation or wiki.

---

### Preventive Action 2: Automate DWM Stability Test in Image Build Pipeline

**What:** Implement an automated post-build smoke test that validates DWM stability.

**Specific change:**

Add a build step to your image CI/CD pipeline (e.g., Azure DevOps, GitHub Actions, or custom orchestration):

```yaml
# Pseudocode: Add to image build pipeline after final provisioning step

Post-Build-Validation:
  - Name: "DWM Stability Check"
  - Trigger: After image provisioning completes, before marking image as "ready for release"
  - Steps:
    1. Deploy a temporary VM using the candidate image.
    2. Wait for the VM to reach "Running" state.
    3. Initiate an RDP session (or use Azure Run Command) to the VM.
    4. Query event logs:
       - Get-WinEvent -FilterHashtable @{LogName='System';ID=9011} to confirm DWM start
       - Get-WinEvent -FilterHashtable @{LogName='Application';ID=1000} to check for dwm.exe crashes
       - Get-WinEvent -FilterHashtable @{LogName='System';ID=9009} to check for DWM exits
    5. Fail the build if any Event 1000 (dwm.exe fault) or Event 9009 (DWM exit) is detected.
    6. Pass the build if Event 9011 appears with no 1000/9009 entries.
    7. Clean up temporary VM.
  - Output: Build artifact tagged "DWM_PASS" or "DWM_FAIL"
  - On Failure: Block image from advancing to staging environment; notify image engineering team.
```

**Owner:** DevOps / Image Pipeline Team

**Timeline:** Implement within 2 sprints (justify based on your sprint length).

**Tools:** Leverage Azure Pipelines, PowerShell, or your existing build orchestration framework.

**Evidence:** Build pipeline YAML or definition updated; smoke test job logs captured and archived with each build.

---

### Preventive Action 3: Enforce Staged Pool Rollout with Canary Gate

**What:** Formalise a change management policy that blocks image updates to all hosts until a canary host passes a stability gate.

**Specific change:**

Update your **Change Management Process** (e.g., in ServiceNow, Jira, or internal wiki):

```
POLICY: Staged Image Rollout with Canary Validation

Trigger: Any image version update to a production AVD host pool.

Steps:
  1. Identify the target pool (e.g., POOL-FIN-01).
  2. BLOCK: Do not update all hosts simultaneously.
  3. CANARY: Select one session host as the canary (e.g., SHFIN-01-A).
  4. TIMING: Deploy the new image to the canary host at least 2 hours before planned rollout to remaining hosts.
  5. GATE: Capture Windows event logs on the canary host for a 30-minute observation window:
     - Query Event 1000 (dwm.exe crashes): Count MUST be 0.
     - Query Event 9009 (DWM exits): Count MUST be 0.
     - Query Event 40 (disconnects): Count MUST be 0 or < 2 (acceptable for normal churn).
  6. DECISION:
     - If gate PASSES: Approve rollout to remaining hosts in 25% batches.
     - If gate FAILS: Rollback canary immediately; investigate root cause; do not proceed to full rollout.
  7. FULL ROLLOUT: Update all remaining hosts in batches, validating each batch the same way.

Change Owner: Infrastructure/Ops Team
Approval Prerequisite: Canary validation MUST be completed and MUST show "PASS" status before any change approval.
Documentation: Attach canary validation output (event log screenshot or PowerShell output) to the change ticket.
Rollback Trigger: If canary fails or event log gate fails, immediate rollback is mandatory; escalate to Incident Management.
```

**Owner:** Change Management Team (in coordination with Infrastructure/Ops)

**Timeline:** Update change process immediately (before the next image update).

**Evidence:** Change process document updated; all future image changes reference canary validation gate; canary logs archived with each change.

---

### Preventive Action 4: Pin Graphics Driver Versions in Image Builds

**What:** Maintain an explicit approved-versions list for graphics drivers and block any unapproved version from entering production.

**Specific change:**

Create an internal "Approved Driver Versions" document or configuration file:

```
APPROVED GRAPHICS DRIVER VERSIONS (for AVD Images)

Component: igdumd64.dll (Intel User-Mode Graphics Driver, 64-bit)
Approved Versions:
  - 30.0.100.4444 (released 2026-07-15, validated on POOL-FIN-01 and POOL-FIN-02)
  - 30.0.100.4445 (released 2026-07-22, validated on lab VMs)
Not Approved (Known Issues):
  - 31.0.101.5555 (released 2026-08-05, causes DWM crash on session login – see incident #2026-08-06-INC00123)
  - 31.0.101.5544 (released 2026-07-30, breaks DirectX 12 games – see incident #2026-07-31-INC00091)

Update Process:
  1. New driver release from vendor (Intel) arrives.
  2. Image engineering tests driver on a lab clone of POOL-FIN-01 image.
  3. If testing passes DWM smoke test and no reported issues:
     - Add version to "Approved Versions" list.
     - Document test results and approval date.
  4. If testing fails:
     - Add version to "Not Approved" list.
     - Document failure reason and link to any related incidents.
  5. Image build automation MUST check the approved list before incorporating driver files.
     If driver version is not on the list, build fails with error: "Unapproved driver version. Update APPROVED_VERSIONS list or escalate to Image Engineering."

Owner: Image Engineering Team
Review Cadence: Quarterly or when new vendor releases arrive (whichever is more frequent)
```

**Owner:** Image Engineering Team

**Timeline:** Create approved-versions document within 1 sprint; integrate into build automation within 2 sprints.

**Evidence:** Approved versions document created and stored in version control; build pipeline updated to reference and enforce the list; build logs show "driver version approved" or "driver version rejected" messages.

---

### Preventive Action 5: Separate Pool Update Schedules

**What:** Enforce a policy that pools designed to serve the same business function (e.g., POOL-FIN-01 and POOL-FIN-02) are never updated in the same maintenance window.

**Specific change:**

Update your **Change Calendar** or **Infrastructure Maintenance Schedule**:

```
POLICY: Staggered Pool Maintenance Windows

Definition: "Equivalent pools" are two or more host pools that serve the same business unit, use identical base images, and are intended to provide failover/redundancy for each other.
  Examples: POOL-FIN-01 and POOL-FIN-02, POOL-HR-PRIMARY and POOL-HR-SECONDARY

Requirement:
  1. POOL-FIN-01 receives image or driver updates in Week 1 of the month.
  2. POOL-FIN-02 receives the SAME image or driver update in Week 3 of the month (at least 2 weeks later).
  3. No exceptions: Even if POOL-FIN-02 is ready earlier, defer update to Week 3.
  4. Rationale: If POOL-FIN-01 update causes an incident, POOL-FIN-02 remains healthy and provides business continuity. By deferring POOL-FIN-02, we gain 2 weeks of real-world validation before risking the failover pool.

Escalation: If business requires synchronous updates (e.g., security patch that must be deployed immediately), escalate to [VP/Director of Infrastructure] for risk approval.

Maintenance Calendar: Update the annual infrastructure calendar to reflect staggered windows for all equivalent pool pairs.
```

**Owner:** Change Management / Infrastructure Planning

**Timeline:** Immediate – update change process; update 2026 maintenance calendar for all pool pairs.

**Evidence:** Maintenance calendar updated and published; all future image/driver changes scheduled on staggered dates; change tickets include pool maintenance window reference.

---

### Preventive Action 6: Create Monitoring Alert for DWM Crash Loop

**What:** Implement a real-time alert that fires when multiple Event 1000 (dwm.exe) entries occur within a short time window on any AVD host, enabling rapid detection and escalation.

**Specific change:**

In your monitoring platform (e.g., Azure Monitor, Splunk, ELK, or equivalent), create a new alert rule:

```
Alert Name: "AVD DWM Crash Loop Detected"
Severity: Critical
Monitored Resource: All AVD session hosts (POOL-FIN-01, POOL-FIN-02, and others)

Alert Condition:
  - Log source: Windows Event Log (Application channel)
  - Event ID: 1000 (Application Error)
  - Message filter: Contains "dwm.exe" AND Contains "igdumd64.dll"
  - Threshold: 3 or more events within a 5-minute window on a single host
  - Time window: Evaluate every 1 minute (rolling 5-minute window)

When Triggered:
  1. Alert fires to [Ops On-Call Team] via PagerDuty, Slack, or email.
  2. Alert includes:
     - Host name (SHFIN-01-A)
     - Host pool (POOL-FIN-01)
     - Event count and timespan (e.g., "4 events in 4 minutes")
     - Sample event message (faulting module, exception code, file version)
     - Link to host's event log in Azure Portal
  3. Ops team investigates (following the Detection section of this KB).
  4. Escalation: If root cause is image/driver regression, page Infrastructure on-call.

Maintenance:
  - Review alert thresholds quarterly; adjust if false-positive rate exceeds 5% per week.
  - Test alert functionality monthly.
  - Document any alert tuning in the monitoring runbook.
```

**Owner:** Monitoring / Operations Team

**Timeline:** Implement within 2 sprints.

**Tools:** Azure Monitor (recommended for Azure-native environment), or integrate with existing monitoring platform.

**Evidence:** Alert rule created in monitoring system; alert test-fired successfully; documented in runbook.

---

### Preventive Action 7: Document Graphics Driver Validation in AVD Image Runbook

**What:** Create or update the AVD image build and release runbook to include specific graphics driver compatibility verification steps and rollback procedures.

**Specific change:**

Add a new section to your **AVD Image Build & Release Runbook** (internal documentation):

```
SECTION: Graphics Driver Validation

Purpose: Ensure graphics drivers (especially Intel igdumd64.dll) are compatible with the AVD session host environment and will not cause DWM crashes.

Prerequisite Checks:
  1. Obtain approved driver version from [APPROVED_VERSIONS.txt] (maintained by Image Engineering).
  2. Confirm driver binary version matches the approved version.
  3. Review vendor release notes for known AVD/remote display incompatibilities.

Test Procedure:
  1. Build candidate image with the target driver version.
  2. Deploy candidate image to a lab VM (non-production).
  3. Connect via RDP/AVD client and log in as a test user.
  4. Verify DWM starts cleanly:
     - Check Event 9011 (Desktop Window Manager started)
     - Check Event 9009 count is 0 (no DWM exits)
     - Check Event 1000 count is 0 (no application crashes mentioning dwm.exe or igdumd64.dll)
  5. Run the following command on the lab VM:
     ```powershell
     Get-Item 'C:\Windows\System32\igdumd64.dll' | Select-Object FullName,@{Name='FileVersion';Expression={$_.VersionInfo.FileVersion}}
     ```
     Confirm output version matches approved version.

Acceptance Criteria:
  - PASS: Event 9011 present, Event 1000 and 9009 counts are 0, igdumd64.dll version matches approved list.
  - FAIL: Event 1000 or 9009 detected; image is rejected and returned to build process.

If FAIL:
  1. Investigate vendor driver release notes for known issues.
  2. Downgrade driver to previous approved version.
  3. Rebuild image and re-test.
  4. If downgrade succeeds, document the failed version in [APPROVED_VERSIONS.txt] under "Not Approved" section.

Rollback Procedure (if driver causes issues in production):
  1. Identify the known-good driver version used by unaffected pool (e.g., POOL-FIN-02).
  2. Create a lab image with the known-good driver version.
  3. Deploy lab image to a canary host in the affected pool (e.g., SHFIN-01-A).
  4. Test canary host (repeat Test Procedure above).
  5. If canary passes, reimage all affected hosts to the known-good image.
  6. Document root cause and update [APPROVED_VERSIONS.txt].
```

**Owner:** Image Engineering Team

**Timeline:** Update runbook within 1 sprint.

**Evidence:** Runbook document updated and reviewed; included in image engineering training materials; referenced in build checklist.

---

### Preventive Action 8: Mandatory Post-Deployment Monitoring Window

**What:** Enforce a minimum active monitoring window after every production image deployment before closing the change.

**Specific change:**

Update your **Change Management Process** (in ServiceNow, Jira, or your change system):

```
REQUIREMENT: Post-Deployment Monitoring (PDM) Window

Applies To: Any image update, driver update, or host pool configuration change that affects production session hosts.

Duration: Minimum 60 minutes after the last host in a batch is successfully reimaged and re-enabled.

Monitoring Activities (all must be completed):
  1. Logon Success Rate:
     - Count successful logins to affected pool in the 60-minute window.
     - Target: 95%+ of login attempts succeed without error.
     - If < 95%: Pause further updates; investigate root cause; consider rollback.
  
  2. Event Log Stability (sample 3+ hosts):
     - Query Event 1000 (dwm.exe): Target is 0 events.
     - Query Event 1001 (Application Error, any): Target is < 3 events (acceptable baseline).
     - Query Event 9009 (DWM exits): Target is 0 events.
     - Query Event 40 (session disconnect): Target is 0 events (or < number-of-hosts in the batch).
     - If thresholds exceeded: Investigate; pause further updates if needed.
  
  3. User Feedback Channel:
     - Monitor service desk queue, Teams channel, email, or tickets for user reports.
     - Target: 0 new reports of black screen, disconnection, or application failures.
     - If reports arrive: Escalate immediately; pause further updates.
  
  4. Performance Baseline:
     - Compare logon times (time from login request to desktop ready) to pre-update baseline.
     - Target: Logon time change < ±10% of baseline.
     - If significant degradation: Investigate performance regression; consider rollback.

Documentation:
  - Capture start time and end time of 60-minute PDM window in the change ticket.
  - Document results of all 4 monitoring activities (success rate, event log summary, user feedback count, performance comparison).
  - Attach supporting evidence (screenshots, PowerShell output, or monitoring system export).

Decision:
  - PASS: All 4 monitoring activities meet targets → Proceed to next batch or declare change complete.
  - FAIL: Any activity fails thresholds → Immediately pause further updates and begin rollback procedure.
  
Change Approval Gate:
  - Change cannot be marked "Closed" or "Successful" until PDM window is complete and all checks PASS.
  - If PDM is skipped, change approval is REJECTED and must be resubmitted with PDM results.
```

**Owner:** Change Management Team

**Timeline:** Update change process immediately; enforce on all changes starting with the next image update.

**Evidence:** Change ticket template updated to include PDM section; all future image change tickets include PDM results before closure.

---

### Preventive Controls (Hardened for Execution)

1. **Control 1 (maps to Action 1) - DWM acceptance gate**
  - **Owner/Timing/Type:** **Image owner**; **before deployment**; **manual** checklist execution by image owner during image sign-off.
  - **Pass/Fail signal:** PASS only if Event 9011 count >= 1 and Event 1000(dwm.exe|igdumd64.dll)=0 and Event 9009=0 in first test login window.
  - **If fail:** Reject image, open defect in image backlog, block promotion to release candidate; **Automation note:** parse exported EVTX via pipeline PowerShell gate.

2. **Control 2 (maps to Action 2) - Pipeline smoke gate**
  - **Owner/Timing/Type:** **Release engineer**; **before deployment**; **automated** CI/CD job on every candidate image build.
  - **Pass/Fail signal:** PASS when job emits `DWM_PASS` artifact and logs show Event9011>=1, Event1000=0, Event9009=0; else FAIL.
  - **If fail:** Pipeline blocks artifact promotion and posts failure to release channel; [REQUIRES: image CI/CD stage with log-query capability].

3. **Control 3 (maps to Action 3) - Canary rollout gate**
  - **Owner/Timing/Type:** **Change manager** (execution by **DWP engineer**); **during deployment**; **manual gate** in change ticket.
  - **Pass/Fail signal:** PASS only if 30-minute canary window shows Event1000=0, Event9009=0, and Event40 <= 1 on canary host.
  - **If fail:** Stop rollout, rollback canary host to last known-good image, escalate incident severity and update change status to Failed.

4. **Control 4 (maps to Action 4) - Driver allowlist enforcement**
  - **Owner/Timing/Type:** **Image owner**; **before deployment**; **automated** version check against approved-driver manifest.
  - **Pass/Fail signal:** PASS when `igdumd64.dll` file version matches allowlist entry; FAIL on missing or blocked version.
  - **If fail:** Build hard-fails with `UNAPPROVED_DRIVER_VERSION`; create review task for image owner; [REQUIRES: version-controlled driver manifest + build validation script].

5. **Control 5 (maps to Action 5) - Staggered equivalent-pool windows**
  - **Owner/Timing/Type:** **Change manager**; **before deployment**; **manual** scheduling validation at CAB/change approval.
  - **Pass/Fail signal:** PASS only when paired pools have maintenance windows >= 14 days apart in approved calendar entries.
  - **If fail:** Reject or re-schedule change request before execution; **Automation note:** calendar-policy check via change API pre-approval.

6. **Control 6 (maps to Action 6) - Crash-loop alerting**
  - **Owner/Timing/Type:** **DWP engineer**; **during deployment** (and steady state); **automated** alert rule on session hosts.
  - **Pass/Fail signal:** Control is healthy when test alert succeeds monthly and false-positive rate < 5%/week; incident trigger is Event1000>=3 in 5 min/host.
  - **If fail:** If control test fails, create monitoring incident P2; if threshold triggers, page on-call and pause active rollout batch; [REQUIRES: centralized event ingestion/alerting].

7. **Control 7 (maps to Action 7) - Runbook step conformance**
  - **Owner/Timing/Type:** **Image owner**; **before deployment**; **manual** runbook attestation in release checklist.
  - **Pass/Fail signal:** PASS only if checklist has completed evidence for driver version check + DWM event checks attached to change.
  - **If fail:** Block release approval until evidence is attached; **Automation note:** enforce required artifacts with change-template validation rules.

8. **Control 8 (maps to Action 8) - Post-deployment validation gate**
  - **Owner/Timing/Type:** **Change manager** (execution by **DWP engineer**); **after deployment**; **manual** validation window.
  - **Pass/Fail signal:** PASS only if 60-minute window meets all: login success >= 95%, Event1000=0, Event9009=0, black-screen tickets=0.
  - **If fail:** Keep change open, halt next batch, and trigger rollback decision within 15 minutes using rollback thresholds below.

9. **Control 9 (Gap add: explicit rollback trigger threshold)**
  - **Owner/Timing/Type:** **Release engineer**; **during deployment** and **after deployment**; **automated trigger + manual approval**.
  - **Pass/Fail signal:** Trigger rollback recommendation if any host has Event1000>=2 in 10 min, or pool login success < 92% for 15 min.
  - **If fail/triggered:** Auto-create rollback task, freeze rollout state, require change manager approve execute/no-execute within 10 minutes; [REQUIRES: rollback orchestration hook].

10. **Control 10 (Gap add: incident-to-knowledge update loop)**
  - **Owner/Timing/Type:** **Service desk lead**; **after deployment** (incident closure stage); **manual** KB/runbook update control.
  - **Pass/Fail signal:** PASS when incident closure checklist links updated KB/runbook/checklist entries and a dated change note within 2 business days.
  - **If fail:** Incident cannot be marked "Problem Closed"; **Automation note:** enforce mandatory knowledge-link field in closure workflow.

**Gap check result:** Pre-deployment test gate, in-flight monitoring, post-deployment validation, and rollback controls existed but are now measurable and threshold-based; the explicit closure-time knowledge update loop was missing and is now added as Control 10.

---

### Preventive Action Summary

1. Action: Add DWM stability to image acceptance criteria | Owner: Image Engineering | Timeline: Before next release | Evidence: Checklist updated
2. Action: Automate DWM smoke test in build pipeline | Owner: DevOps | Timeline: Within 2 sprints | Evidence: Build job added, logs archived
3. Action: Enforce canary gate in change process | Owner: Change Management + Ops | Timeline: Immediate | Evidence: Change process document, next change includes canary validation
4. Action: Pin graphics driver versions | Owner: Image Engineering | Timeline: Within 2 sprints | Evidence: Approved versions document created, build automation enforces
5. Action: Stagger pool maintenance windows | Owner: Change Management | Timeline: Immediate | Evidence: Maintenance calendar updated for 2026
6. Action: Create DWM crash loop alert | Owner: Monitoring / Ops | Timeline: Within 2 sprints | Evidence: Alert rule created, tested, and documented
7. Action: Update image build runbook | Owner: Image Engineering | Timeline: Within 1 sprint | Evidence: Runbook document updated and reviewed
8. Action: Mandate post-deployment monitoring window | Owner: Change Management | Timeline: Immediate | Evidence: Change process updated, PDM template added
9. Action: Add explicit rollback trigger thresholds | Owner: Release Engineering + Change Management | Timeline: Immediate | Evidence: Rollback trigger policy and orchestration hook documented/tested
10. Action: Enforce incident-to-knowledge closure update | Owner: Service Desk Lead + Change Management | Timeline: Immediate | Evidence: Closure checklist/template requires KB/runbook update links

**Completion Target:** All 10 preventive actions should be implemented within 3 sprints. Actions 1, 3, 5, 8, 9, and 10 can begin immediately (within 1 sprint). Actions 2, 4, 6, and 7 follow in sprints 2–3.

---

## Related

### Other Incidents or KB Articles This Connects To

1. **Related Incident: 2026-08-06-INC00123** (This incident)
   - **Title:** "AVD Black Screen on POOL-FIN-01 – Intel Driver Regression"
   - **Status:** Resolved
   - **Files:** 
     - [Day4/triage-summary-avd-black-screen-pool-fin-01.md](Day4/triage-summary-avd-black-screen-pool-fin-01.md)
     - [Day4/rca-avd-black-screen-pool-fin-01-2026-08-06.md](Day4/rca-avd-black-screen-pool-fin-01-2026-08-06.md)
     - [Day4/closure-note-avd-black-screen-pool-fin-01-2026-08-06.md](Day4/closure-note-avd-black-screen-pool-fin-01-2026-08-06.md)
     - [Day5/runbook-avd-black-screen-pool-fin-01-driver-regression-2026-08-07.md](Day5/runbook-avd-black-screen-pool-fin-01-driver-regression-2026-08-07.md)
   - **Relevance:** Primary incident document; this KB article is the detailed L2/L3 version of the runbook.

2. **Related Incident: 2026-07-31-INC00091** (Cross-Reference)
   - **Title:** "AVD DirectX 12 Application Crash – Intel Driver Version 31.0.101.5544"
   - **Summary:** Similar driver regression pattern but manifested as application crash (not DWM crash). Root cause: unapproved Intel driver version introduced in image build without vendor compatibility testing.
   - **Key learning:** Multiple driver versions from vendor 31.0.101.x family have caused issues. Recommend pinning to 30.0.100.x family until 31.x family is thoroughly validated.
   - **Related to this KB:** Supports Preventive Action 4 (pin driver versions) and reinforces the need for driver approval process.

3. **Related KB: "Azure Virtual Desktop – Event Log Reference for Common Issues"** (Documentation)
   - **What it covers:** Reference guide for Event IDs in AVD environments, including Event 1000, 9009, 9011, 21, 40.
   - **Relevance:** Provides background for engineers unfamiliar with AVD event structure. Recommended reading for operators new to AVD support.

4. **Related KB: "AVD Image Build Process – Acceptance Criteria and Quality Gates"** (Documentation)
   - **What it covers:** Overview of how AVD images are built, tested, and promoted to production.
   - **Relevance:** This KB article assumes familiarity with the image build process. New engineers should read this reference first to understand the context.

5. **Related KB: "Session Host Driver Management – Graphics, NIC, and Storage"** (Documentation)
   - **What it covers:** Best practices for driver versioning, testing, and rollback in hypervisor/virtualised environments.
   - **Relevance:** Provides vendor-agnostic guidance on driver management; complements Preventive Actions 4 and 7.

6. **Related Process: Change Management – Image and Driver Updates** (Process Documentation)
   - **What it covers:** The formal change control process for production infrastructure updates.
   - **Relevance:** This KB reinforces the need to follow change management; Preventive Actions 3, 5, and 8 are specific enhancements to the existing change process.

7. **Related Monitoring: Azure Monitor – Custom Alert for Compositor Stability** (Monitoring)
   - **What it covers:** Implementation of real-time alerts for graphics/DWM issues.
   - **Relevance:** Preventive Action 6 refers to this monitoring configuration.

8. **Related Incident: Finance Shared Drives Access Denied – 2024-03-15** (Comparison)
   - **Title:** "Finance Shared Drives – Access Denied After Migration"
   - **Files:** [Day4/rca-finance-shared-drives-2024-03-15.md](Day4/rca-finance-shared-drives-2024-03-15.md)
   - **Why included:** Though unrelated to driver crashes, this incident also affected the Finance business unit. Both incidents share:
     - Same affected user population (Finance team).
     - Same impact timeframe (business hours disruption).
     - Both required rapid incident response and cross-team coordination.
   - **Learning:** Finance infrastructure is critical; any issue affecting Finance systems should trigger escalation and prioritised triage.

---

## Document Metadata

| Attribute | Value |
|---|---|
| KB Article ID | KB-2026-08-07-001 |
| Title | L2/L3 Knowledge Base: AVD Black Screen – DWM Crash Loop (Intel Driver Regression) |
| Version | v1.0 |
| Last Updated | 07/08/2026 |
| Status | Draft |
| Author | Infrastructure Operations Team |
| Audience | L2/L3 Infrastructure Engineers, Platform Operations, On-Call Teams |
| Incident Reference | 2026-08-06-INC00123 |
| Related Runbook | [Day5/runbook-avd-black-screen-pool-fin-01-driver-regression-2026-08-07.md](Day5/runbook-avd-black-screen-pool-fin-01-driver-regression-2026-08-07.md) |
| Approval Status | Pending review by [Infrastructure Manager Name] |

---

## Revision History

| Version | Date | Author | Change Summary |
|---|---|---|---|
| v1.0 | 07/08/2026 | Ops Team | Initial draft from RCA and runbook; comprehensive L2/L3 article with all required sections. |

---

## Questions for Feedback (Before Publishing)

- [ ] Are all Azure Portal path names accurate for your subscription/tenant environment?
- [ ] Are the Event IDs and log locations validated against your actual AVD event logs?
- [ ] Do the Preventive Actions align with your organization's change management and infrastructure governance?
- [ ] Have you reviewed the Rollback section with your incident commander to ensure procedures are feasible under pressure?
- [ ] Are there any driver versions or tools in your environment not mentioned in this KB that should be added?

**Next Step:** Submit this draft for review by your Infrastructure Manager and Senior Ops Team before publishing to the live KB system.
