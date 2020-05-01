# Deploy and IPSec VPN and Router on Packet Baremetal
This repo will allow you to deploy a VyOS router onto a baremetal node in Packet. It will then generate a config file to setup an IPSec tunnel with a Cisco 1000v from Equinix's ***Network Edge***. As of now there is no way to fully automate the configuration of the router (That I've figured out). So we'll be doing a few steps by hand.
## Install Terraform 
Terraform is just a single binary.  Visit their [download page](https://www.terraform.io/downloads.html), choose your operating system, make the binary executable, and move it into your path. 
 
Here is an example for **macOS**: 
```bash 
curl -LO https://releases.hashicorp.com/terraform/0.12.18/terraform_0.12.18_darwin_amd64.zip 
unzip terraform_0.12.18_darwin_amd64.zip 
chmod +x terraform 
sudo mv terraform /usr/local/bin/ 
``` 
 
## Download this project
To download this project, run the following command:

```bash
git clone https://github.com/c0dyhi11/packet-router.git
cd packet-router
```

## Initialize Terraform 
Terraform uses modules to deploy infrastructure. In order to initialize the modules your simply run: `terraform init`. This should download modules into a hidden directory `.terraform` 
 
## Modify your variables 
You will need to set three variables at a minimum and there are a lot more you may wish to modify in `variables.tf`
```bash 
cat <<EOF >terraform.tfvars 
auth_token = "cefa5c94-e8ee-4577-bff8-1d1edca93ed8" 
project_id = "42259e34-d300-48b3-b3e1-d5165cd14169" 
ipsec_peer_public_ip = "192.168.2.2"
EOF 
``` 
## Deploy terraform template
```bash
terraform apply --auto-approve
```
Once this is complete you should get output similar to this:
```
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

BGP_Password = JSWwskQHFt2KBSZu2O
IPSec_Pre_Shared_Key = iORwUH75vMxQkyX5AZ85
IPSec_Private_IP_CIDR = 169.254.254.254/30
IPSec_Public_IP = 147.75.63.66
Out_of_Band_Console = ssh 81b3e87b-3a31-4957-9898-a67e3ddfaf05@sos.iad2.packet.net
SSH = ssh vyos@147.75.63.66
VyOS_Config_File = ./vyos.conf
```

## Install VyOS to disk
What we want to do here is install VyOS to the local disk on the system and set a password.

There is no automated way to do this yet (I have been informed there is, it uses cloud-init, I'll look into this), so you need too SSH into the box and run the command `install image` and follow the prompts. Find the **SSH** command in the terraform outputs.

I've attached the output of me doing this with all of the input's in **Bold**. A lot of the options can use the defaults.
<pre>
$ <b>ssh vyos@147.75.63.66</b>
vyos@vyos:~$ <b>install image</b>
Welcome to the VyOS install program.  This script
will walk you through the process of installing the
VyOS image to a local hard drive.
Would you like to continue? (Yes/No) [Yes]: <b>Yes</b>
Probing drives: OK
Looking for pre-existing RAID groups...none found.
The VyOS image will require a minimum 2000MB root.
Would you like me to try to partition a drive automatically
or would you rather partition it manually with parted?  If
you have already setup your partitions, you may skip this step

Partition (Auto/Parted/Skip) [Auto]: <b>Auto</b>

I found the following drives on your system:
 sda	480103MB
 sdb	480103MB
 sdc	240057MB
 sdd	240057MB


Install the image on? [sda]:<b>sdc</b>

This will destroy all data on /dev/sdc.
Continue? (Yes/No) [No]: <b>Yes</b>

How big of a root partition should I create? (2000MB - 240057MB) [240057]MB: <b>240057MB</b>

Creating new GPT entries.
GPT data structures destroyed! You may now partition the disk using fdisk or
other utilities.
Creating new GPT entries.
The operation has completed successfully.
Creating filesystem on /dev/sdc3: OK
Done!
Mounting /dev/sdc3...
What would you like to name this image? [1.2.2]: <b>1.2.2</b>
OK.  This image will be named: 1.2.2
Copying squashfs image...
Copying kernel and initrd images...
Done!
I found the following configuration files:
    /opt/vyatta/etc/config/config.boot
    /opt/vyatta/etc/config.boot.default
Which one should I copy to sdc? [/opt/vyatta/etc/config/config.boot]: <b>/opt/vyatta/etc/config/config.boot</b>

Copying /opt/vyatta/etc/config/config.boot to sdc.
Enter password for administrator account
Enter password for user 'vyos':
Retype password for user 'vyos':
I need to install the GRUB boot loader.
I found the following drives on your system:
 sda	480103MB
 sdb	480103MB
 sdc	240057MB
 sdd	240057MB


Which drive should GRUB modify the boot partition on? [sda]:<b>sdc</b>

Setting up grub: OK
Done!
</pre>

## Set a VyOS password
Wait... Didn't VyOS just ask me to set a password for the **vyos** two minutes ago? Yep! I'm not sure what that does... But I had to set the password via config mode myself. (I even tried a reboot thinking maybe this only takes effect after the server boots from the newly installed disk... No dice!) Here we go:
<pre>
vyos@vyos:~$ <b>conf</b>
[edit]
vyos@vyos# <b>set system login user vyos authentication plaintext-password '$3cur3P@$$w0rd!'</b>
[edit]
vyos@vyos# <b>commit</b>
[edit]
vyos@vyos# <b>save</b>
Saving configuration to '/config/config.boot'...
Done
[edit]
vyos@vyos# <b>exit</b>
exit
vyos@vyos:~$
</pre>

## Disable Cloud-Init
For some reason cloud-init gets in our way as we move forward. So we need to get rid of cloud-init to proceed.
<pre>
vyos@vyos:~$ <b>sudo apt remove cloud-init -y</b>
vyos@vyos:~$ <b>sudo rm -f /etc/network/interfaces.d/50-cloud-init.cfg</b>
</pre>

## Apply VyOS Config
Ok so I had some issues here geting the config working properly via SSH. I think we get disconnected when we change the interface config away from DHCP and to static. So I had to apply the config via the SOL console.

Find the **Out_of_Band_Console** command in the Terraform output. Also you set the *vyos* users password in a previous step, you'll need that to login via the console.

Once you run the **Out_of_Band_Console** command you may need to press ***Enter*** a couple times to be greeted with the ***vyos login:*** prompt.

Once you've logged in and and are at the command line you'll need to go into ***config*** mode, and paste in the contents of the ***VyOS_Config_File*** from the terraform outputs (You can paste in multiple lines at once, but see the note below).

There are a few places where you will see **### STOP HERE ###**. Read the comments in the file and do as instructed.

## Done! Go setup the other side of the VPN!

