# Lab 1: Active Directory, DHCP, NAT and Bulk User Creation

## Goal
Build a small corporate-style Windows network from scratch: a domain controller
that provides Active Directory, DNS, DHCP and NAT routing, plus a Windows 10
client that joins the domain and logs in with a domain account.

## Progress
- [x] Windows Server 2022 VM built in VMware with two network adapters
- [x] Adapters renamed, static IP set on the internal adapter, server renamed
- [x] AD DS installed, domain `kinglab.local` created
- [x] Dedicated domain admin account created and tested
- [x] Remote Access (Routing) installed, NAT configured
- [x] DHCP role installed and authorized
- [x] DHCP scope and scope options configured, scope activated
- [x] Users bulk-created with PowerShell
- [ ] Windows 10 Pro client joined to the domain
- [ ] Verification complete

## Environment
| Item | Value |
|------|-------|
| Hypervisor | VMware Workstation (VM hardware compatibility: Workstation 25H2) |
| DC | Windows Server 2022 Standard (Evaluation), hostname `ADDC01`, 8 GB RAM, 4 vCPU, 100 GB disk |
| Client | Windows 10 Pro, hostname `CLIENT1` (planned) |
| Domain | `kinglab.local` (NetBIOS: `KINGLAB`) |
| Internal network | 172.16.0.0/24 (VMware LAN Segment) |

## Network design
![diagram](images/00-network-diagram.png)

- The DC has two network adapters: adapter 1 on NAT (internet via the host) and
  adapter 2 on a LAN Segment (private lab network).
- A LAN Segment is used for the internal network because VMware's built-in NAT
  and host-only networks run their own DHCP service, which would conflict with
  the DHCP server built on the DC.
- DC internal IP: `172.16.0.1/24`, no default gateway, DNS set to itself
  (`127.0.0.1`).
- Client (planned): one adapter on the same LAN Segment, gets its settings from
  DHCP and reaches the internet through the DC.

## Steps

### 1. Create the DC virtual machine
Windows Server 2022 VM `ADDC01` with 8 GB RAM, 4 processors and a 100 GB disk.
Adapter 1 is set to NAT and adapter 2 to a LAN Segment.
![DC VM settings](images/01-dc-vm-settings.png)
![DC network adapters](images/02-dc-network-adapters.png)

### 2. Identify and rename the network adapters
In Network Connections, one adapter had a normal address (192.168.233.144 from
VMware NAT) and the other showed "Unidentified network" with no DHCP available.
I renamed them `Internet` and `Internal` so they are easy to tell apart when
configuring NAT.
![Adapters renamed](images/04-adapters-renamed.png)

### 3. Set a static IP on the Internal adapter
Internal adapter: IP `172.16.0.1`, mask `255.255.255.0`, no default gateway,
preferred DNS `127.0.0.1`. The Internet adapter stays on DHCP. Confirmed with
`ipconfig`.
![Static IP](images/05-static-ip.png)
![ipconfig result](images/05b-ipconfig.png)

### 4. Rename the server
Renamed the server to `ADDC01`, restarted, and confirmed with `hostname`.
![Rename server](images/04b-rename-server.png)

### 5. Install the AD DS role
Server Manager > Add Roles and Features > Active Directory Domain Services,
with the required management tools. Installation succeeded and showed
"Configuration required" until the server was promoted.
![AD DS role](images/06-adds-role.png)
![AD DS installed](images/06b-adds-installed.png)

### 6. Promote the server to a domain controller
Promoted the server with a new forest, `kinglab.local`. Forest and domain
functional levels were left at Windows Server 2016, with DNS server and Global
Catalog enabled. NetBIOS name `KINGLAB`. Set a DSRM password. A DNS delegation
warning appeared (normal for a new forest with no parent zone). The prerequisite
check passed, I took a VMware snapshot, then installed. The server restarted
and the login screen showed `KINGLAB\Administrator`.
![New forest](images/07a-new-forest.png)
![DNS delegation warning](images/07b-dns-delegation-warning.png)
![Review options](images/07-promote-dc.png)
![Prerequisite check](images/07c-prereq-check.png)
![Domain login screen](images/07d-domain-login.png)
![whoami](images/07e-whoami.png)
![ADUC](images/07f-aduc-empty-domain.png)

### 7. Create an admin OU and a dedicated domain admin account
Created an OU named `_ADMINS` and an account `a-ktolentino` (King Tolentino)
inside it, with "Password never expires" set (lab only). Added the account to
**Domain Admins**, then signed in with it to confirm.
![Admin OU](images/08-admin-ou.png)
![Admin user](images/08b-admin-user.png)
![Domain Admins membership](images/09-domain-admins.png)
![Admin login](images/09b-admin-login.png)

### 8. Install Remote Access (Routing) and configure NAT
Installed the Remote Access role with the Routing role service (the wizard also
added DirectAccess and VPN (RAS), Web Server (IIS) and the RAS Connection
Manager Administration Kit as dependencies). In Routing and Remote Access I ran
"Configure and Enable Routing and Remote Access", chose Network address
translation (NAT), and selected the `Internet` adapter as the public interface.
Verified under IPv4 > NAT that the Internet interface is Public with "Enable NAT
on this interface" ticked.
![Remote Access confirm](images/10a-remote-access-confirm.png)
![Remote Access installed](images/10b-remote-access-installed.png)
![NAT interface selection](images/10-nat.png)
![NAT configured](images/10c-nat-green.png)
![NAT interfaces](images/10d-nat-interfaces.png)
![NAT public interface](images/10e-nat-public.png)

### 9. Install and authorize DHCP
Installed the DHCP Server role, then ran "Complete DHCP configuration", which
created the DHCP security groups and authorized the server in Active Directory
using `KINGLAB\a-ktolentino`. Restarted the DHCP service so the security groups
took effect. Both IPv4 and IPv6 show green checkmarks in the DHCP console.
![DHCP confirm](images/11a-dhcp-confirm.png)
![DHCP installed](images/11b-dhcp-installed.png)
![DHCP post-install](images/11c-dhcp-post-install.png)
![DHCP console](images/11d-dhcp-console.png)

### 10. Create and configure the DHCP scope
In the DHCP console I ran IPv4 > New Scope. Scope name `172.16.0.100-200`.
Address range `172.16.0.100` to `172.16.0.200`, length 24 (mask 255.255.255.0).
The range starts at .100 so that .1 to .99 stay free for fixed-address devices
such as the DC at .1.
![DHCP range](images/11e-dhcp-range.png)

I added no exclusions, since all fixed-address devices sit below the range, and
kept the default 8-day lease, which suits a small lab of desktop-style machines.
In the options pages I set:
- Router (default gateway): `172.16.0.1`, the DC, because it runs NAT
- Parent domain `kinglab.local` and DNS server `172.16.0.1`
- WINS: none (see Problems below)

I chose to activate the scope at the end of the wizard. Under Scope Options the
console shows `003 Router` = `172.16.0.1`, `006 DNS Servers` = `172.16.0.1` and
`015 DNS Domain Name` = `kinglab.local`.
![DHCP scope options](images/11f-dhcp-scope-options.png)

### 11. Bulk-create users with PowerShell
First I created an OU named `_USERS` in Active Directory Users and Computers to
hold the lab users.
![USERS OU](images/12a-users-ou.png)

I looked up its path with `Get-ADOrganizationalUnit`, which returned
`OU=_USERS,DC=kinglab,DC=local`, then saved a script as `New-LabUsers.ps1`
and ran it in PowerShell ISE **as administrator**. It loops through a list of
ten names, builds each username from the first initial plus the last name
(Maria Santos becomes `msantos`), and creates an enabled account in `_USERS`
with a shared lab password. The values I set for this lab are the domain
`kinglab.local`, the OU path above and the list of names.

```powershell
$Password = ConvertTo-SecureString "Password1!" -AsPlainText -Force
$OU       = "OU=_USERS,DC=kinglab,DC=local"
$Domain   = "kinglab.local"

$Names = @(
    "Maria Santos", "Juan Dela Cruz", "Ana Reyes", "Carlo Garcia", "Liza Mendoza",
    "Mark Villanueva", "Joy Ramos", "Paolo Cruz", "Grace Bautista", "Ben Aquino"
)

foreach ($Name in $Names) {
    $First, $Last = $Name -split " ", 2
    $Sam = ($First.Substring(0,1) + $Last).ToLower() -replace " ", ""

    New-ADUser -Name $Name `
        -GivenName $First -Surname $Last `
        -SamAccountName $Sam `
        -UserPrincipalName "$Sam@$Domain" `
        -Path $OU `
        -AccountPassword $Password `
        -Enabled $true `
        -PasswordNeverExpires $true

    Write-Host "Created $Name ($Sam)"
}
```
![Script running](images/12b-bulk-users-script.png)

Afterwards I checked Active Directory Users and Computers and all ten users
were listed in `_USERS`.
![Users in the OU](images/12c-users-in-ou.png)

### 12. Build the Windows 10 client and join the domain (TO DO)
<Windows 10 Pro VM on the same LAN Segment, confirm the DHCP lease and the default
gateway, ping the internet and the domain, rename to CLIENT1, join `kinglab.local`,
log in with a domain account.>

### 13. Verify everything works (TO DO)
| Check | Where / command | Result |
|-------|-----------------|--------|
| Client got a DHCP lease | DHCP > Address Leases on the DC | |
| Client resolves names | `ping google.com` | |
| Client reaches DC by domain name | `ping kinglab.local` | |
| Computer object created | AD Users and Computers > Computers | |
| Domain login works | `whoami` as a domain user on CLIENT1 | |

## Problems I Hit and How I Fixed Them

- **Problem:** The new admin account `a-ktolentino` could not sign in to the
  server ("The sign-in method you're trying to use isn't allowed").
  **Cause:** The Domain Admins membership had not been saved, because I closed
  the Properties window without clicking Apply. A standard domain user cannot log
  on locally to a domain controller.
  **Fix:** Added the account to Domain Admins again, clicked Apply (button greyed
  out), and signed in successfully.
  ![Sign-in not allowed](images/09c-signin-not-allowed.png)

- **Problem:** In the NAT setup wizard, the list of network interfaces was empty,
  so I could not select the public interface.
  **Cause:** The Routing and Remote Access console had not refreshed its
  interface list after the role was installed.
  **Fix:** Cancelled the wizard, closed and reopened the console, and ran the
  wizard again. Both adapters then appeared.
  ![Empty interface list](images/10c-nat-empty-interface-list.png)

- **Problem:** A DNS delegation warning appeared during domain controller
  promotion.
  **Cause:** `kinglab.local` has no parent DNS zone to delegate from.
  **Fix:** None needed. This is expected for a new forest in a lab.

- **Problem:** On the WINS Servers page of the New Scope Wizard, the list already
  contained `192.168.233.2`.
  **Cause:** The wizard copied it from the DC's Internet adapter settings. It is
  the VMware NAT gateway, on a different subnet, and not a WINS server.
  **Fix:** Selected the entry, clicked Remove and left the page empty. DNS
  handles name resolution in this lab, so WINS is not needed.

- **Problem:** The first run of the user script printed "Access is denied" for
  every user, but also printed "Created ..." for each one.
  **Cause:** PowerShell ISE was not running as administrator, so my Domain
  Admins rights were not applied to that session. The script also never checked
  for errors, so its "Created" message printed even when `New-ADUser` failed.
  **Fix:** Reopened ISE with Run as administrator (the title bar shows
  "Administrator:") and ran the script again with no errors. I confirmed the
  result in Active Directory Users and Computers instead of trusting the script
  output.

## Security notes
This is an isolated lab. Simple shared passwords and "Password never expires"
are used for convenience only and would not
be acceptable in production. Windows 10 reached end of support in October 2025,
so it is used here for the lab only.

## What I Learned
- <how DNS, DHCP and NAT fit together>
- <why a separate admin account is used>
- <what /24 means and how I chose the DHCP range>
- <anything else, in your own words>

## What's Next
- Group Policy and file shares (Lab 2)
- Microsoft 365 / Entra ID (Lab 3)

## Credit
Network design and approach follow Josh Madakor's Active Directory home lab video
(VirtualBox, Server 2019), rebuilt in VMware with Windows Server 2022 and
Windows 10, using my own domain name and notes.
