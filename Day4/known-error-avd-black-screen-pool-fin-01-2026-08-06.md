Symptom : Users on POOL-FIN-01 log in successfully and then see a persistent black screen. Some sessions auto-recover after about 30 seconds, while others remain unusable and enter a reconnect/disconnect loop.

Cause : The overnight 02:00 image update to POOL-FIN-01 introduced a defective Intel graphics driver component, igdumd64.dll. During session initialisation, dwm.exe faults in igdumd64.dll with exception 0xc0000005, causing DWM to exit and the session to disconnect.

Scope : Approximately 40% of users connecting to POOL-FIN-01 were affected between about 07:00 and 10:00 on 2026-08-06. POOL-FIN-02 and hosts not updated to the new image were unaffected.

Workaround : Place affected POOL-FIN-01 hosts in drain mode and route new sessions to POOL-FIN-02. This restores user access while remediation is performed on the affected pool.

Permanent fix: Replace/downgrade the faulty Intel graphics driver in the POOL-FIN-01 image to the last known-good version and pin that driver version. Validate on a canary host with repeated multi-user logins, then roll out the corrected image to remaining POOL-FIN-01 hosts in staged batches.

How to spot it: On affected hosts, look for a repeating sequence within seconds of logon: Event 21 (TerminalServices-LocalSessionManager) followed by Event 1000 (Application Error: dwm.exe faulting module igdumd64.dll, exception 0xc0000005), then Event 40 (session disconnected) and Event 9009 (DWM exited with code 0x40010004). The unaffected comparison pattern is Event 9011 (DWM started successfully) with no corresponding Event 1000 in the same window.