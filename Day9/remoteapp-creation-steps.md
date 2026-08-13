# Steps to Create a RemoteApp in Azure Virtual Desktop

This is the exact practical flow used to add Google Chrome as a RemoteApp to the new host pool.

## Purpose

A RemoteApp lets users launch a single published application (for example, Chrome) without opening a full desktop session.

## Prerequisites

- Existing host pool (example: POOL-FIN-01)
- Existing workspace (example: FinBridge-Workspace)
- Existing session host VM (example: sh-fin-01)
- Azure CLI login and correct subscription context
- Permission to create role assignments (Owner or User Access Administrator)

## Step-by-step

1. Verify existing AVD objects.
- Confirm host pool exists.
- Confirm workspace exists.
- Confirm desktop app group exists.

2. Install the target application on the session host.
- Use VM run-command to install Chrome on sh-fin-01.
- Verify path exists: C:\Program Files\Google\Chrome\Application\chrome.exe

3. Create a RemoteApp application group.
- Example name: RAG-POOL-FIN-01
- Type must be RemoteApp
- Link to the same host pool

4. Publish the application object.
- Create app object under RemoteApp group via ARM API.
- Set:
  - friendlyName: Google Chrome
  - filePath: C:\Program Files\Google\Chrome\Application\chrome.exe
  - showInPortal: true

5. Register app groups to the workspace.
- Keep existing desktop app group reference.
- Add the RemoteApp group reference.

6. Assign user access on RemoteApp group.
- Role: Desktop Virtualization User
- Scope: RemoteApp group
- Assignee example: P04@zippyops.in

7. Validate.
- List apps in RemoteApp group and confirm Chrome appears.
- Check workspace applicationGroupReferences includes both DAG and RAG.
- Ask user to refresh AVD client feed.

## Script saved for reuse

- Day9/scripts/create-remoteapp-chrome.ps1

## Notes from this implementation

- In this environment, publishing app via az rest required body from JSON file format (@file).
- Native CLI subgroup for application objects was not available; ARM REST endpoint was used.
