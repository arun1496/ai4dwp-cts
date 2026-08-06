# AVD Black Screen Communications - POOL-FIN-01

## Audience 1 - Non-technical executive

Your access and data are safe. From 07:00 to 10:00, 40% of POOL-FIN-01 users saw a black screen after sign-in; POOL-FIN-02 was unaffected. A 02:00 update added faulty display software. We redirected new sign-ins, restored the last working version, tested one rebuilt host, and rolled out the corrected update. By 10:00 the issue was gone. Future updates will require a test host and sign-in check. If it happens again, try once more, then contact the Service Desk.

## Audience 2 - Affected end-user team

Your access and data are safe. From 07:00 to 10:00, 40% of POOL-FIN-01 users saw a black screen after sign-in; POOL-FIN-02 was unaffected. A 02:00 update added faulty display software, which caused some sessions to stay black after sign-in. We redirected new sign-ins, restored the last working version, tested one rebuilt host, and rolled out the corrected update. By 10:00 the issue was gone. Future updates will require a test host and sign-in check. If it happens again, try once more, then contact the Service Desk.

## Audience 3 - Engineer-to-engineer internal note

Access and data remained safe throughout. From 07:00 to 10:00, roughly 40% of POOL-FIN-01 users hit a post-logon black screen; POOL-FIN-02 was unaffected.

Root cause:
The 02:00 POOL-FIN-01 image update introduced a bad Intel graphics component, igdumd64.dll, which caused DWM to fault during session initialisation and produced the black-screen/disconnect behavior.

Exact action taken:
Affected POOL-FIN-01 hosts were placed in drain mode and new sessions were sent to POOL-FIN-02. The last known-good graphics driver version was restored in the image, one host was rebuilt from the corrected image and tested repeatedly, and the corrected image was then rolled out across the remaining POOL-FIN-01 hosts.

Config detail:
Affected pool: POOL-FIN-01. Unaffected comparison pool: POOL-FIN-02. Triggering change: overnight image update at 02:00.

Verification:
By 10:00 the issue was gone. Repeated test sign-ins on the rebuilt host were successful, and there were no further black-screen reports after the corrected rollout.

Preventive action needed:
Require a canary test host and a post-sign-in graphics stability check before future image rollouts.

If the issue happens again, retry once and contact the Service Desk while triage checks POOL-FIN-01 image and graphics-driver state against POOL-FIN-02.