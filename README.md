Server Checkup

A small Bash script that runs five basic security checks on a Linux machine and prints a short report. It only reads things. It never changes anything on the system.

What it checks
Listening ports (information only): which TCP/UDP ports are open and waiting for connections
Empty passwords: any user in /etc/shadow with a completely empty password field
Extra root users: any account other than root with UID 0
World-writable files: files in /etc, /home and /var that any user can modify
Pending updates (information only): how many packages have updates waiting

Checks 2, 3 and 4 add to the "Issues found" count. Checks 1 and 5 are only for information, because an open port or a pending update isn't automatically a problem.

Usage
bash
chmod +x server_checkup.sh
sudo ./server_checkup.sh

It needs sudo because /etc/shadow can only be read by root. If you forget, the script tells you and stops.

Example output (clean system)
Server checkup - Sat Oct 17 06:01:59 AM EDT 2026
============================
1. Listening ports:
none
2. Users with empty password:
 OK 
3. Extra users with root permission:
 OK 
4. World-writable files (in /etc /home /var):
 OK 
5. Pending updates (not all are security fixes):
1363 packages
===================================
Issues found: 0
Bugs I hit while building it

A security script that says "OK" when it should say "WARNING" is worse than no script, so most of my debugging was about that.

Typos that turned warnings into OK. A space inside != in the awk test, a broken redirect in the find command, and a wrong bracket in an if all made a check silently pass. A clean run looks fine with these bugs in place, so they were only found by reviewing the code line by line, not by running it.
A misspelled counter that only crashes on a real problem. With set -u, using a variable name that was never set stops the script. My issue counter was misspelled in the lines that only run when a warning fires, so a clean run never touched it. I confirmed the fix by triggering a real warning on purpose.
Empty output doesn't prove a check works. Several checks returned nothing on my machine, which could mean "clean" or "broken". I tested each one against data that should be flagged (SSH turned on for the ports check, sample lines with an empty password and an extra root user, and a file I made world-writable on purpose).
Design choices
set -u but not set -e. grep -c returns a failure code when the count is zero, so with set -e the script would stop on a perfectly normal clean result. I checked this with a small test.
A check for required tools. If ss, awk, find or apt is missing, a check could print "none" or "OK" without ever running. The script checks for them first and stops with a clear message. I haven't hit this on Kali, where all four exist, so this is a precaution.
Limitations
Five basic checks. This is a quick look, not a full security audit.
"Issues found" counts failed checks, not individual findings. Fifty writable files still count as one issue.
The script always exits with code 0, even when it finds issues. As it is, a CI pipeline can't use it to fail a build. Exiting with a non-zero code when issues are found is the obvious next step.
The update count includes every pending update. On a rolling release like Kali it can't tell security fixes apart from normal updates, so it's labelled "pending updates", not "vulnerabilities".
The port list is information only. It doesn't judge whether an open port is expected.
The empty-password check only catches empty fields. It says nothing about weak passwords.
The file check only looks inside /etc, /home and /var, and skips other mounted filesystems.
The empty-password and extra-root-user checks were tested against sample data, not by making my own system insecure.
Built and tested on Kali Linux. Other distributions may need small changes, for example if they use a different package manager.
Requirements
Bash
Standard tools: ss, awk, find, apt
Root access (sudo)
