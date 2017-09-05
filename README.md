ec2-kickstart
=============

Perl script for kickstarting an EC2 instance.

_The following is a partial excerpt from my 8/25/11 blog post, which has more context (http://www.dakindesign.com/blog/windows-workstations-in-amazon-ec2/)_

Replace the “xxx” in the variables near the top, then run it. This assumes you:
* Have the EC2 API tools and Cirrus for Route 53 (get them from Amazon’s site)
* Have configured your system such that the EC2 API tools work (e.g. I had to add “export JAVA_HOME=/System/Library/Frameworks/JavaVM.framework/Versions/CurrentJDK/Home” to my .bash_profile)
* Have generated, downloaded, and exported EC2_PRIVATE_KEY and EC2_CERT variables pointing to your Amazon X.509 certificate and private key.

Now when you run the Perl file:
* An instance will be started from your AMI
* Your EBS volume will be attached to the instance (and a snapshot will be taken)
* Your domain name will be updated in Route 53 to point to your new instance's public IP address

Remote Desktop to your Windows address and you’re all set! Shut down the computer when you’re done, and all clean-up will happen automatically (instance termination, EBS volume detachment, elastic IP disassociation).

NOTE: the Perl script specifies that your instance should terminate (rather than stop) when you shut down Windows internally. That allows us to tear it all down by just using the Windows regular shutdown method, instead of using the Amazon web interface or API.

**Note** — as of 6c14ce937e2e1b4f35af33274ed76be7dd136b93, part of the duties of this task (the DNS updating) have been moved to a PowerShell script that is run on the actual host:

```powershell
Initialize-AWSDefaultConfiguration

$hosted_zone = "xxxxxxxxxxxxxx"
$rrset_name = "my.domain.name"

$new_ipv4 = (curl http://169.254.169.254/latest/meta-data/public-ipv4).Content

$change = New-Object Amazon.Route53.Model.Change
$change.Action = "UPSERT"
$change.ResourceRecordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
$change.ResourceRecordSet.Name = $rrset_name
$change.ResourceRecordSet.Type = "A"
$change.ResourceRecordSet.TTL = 60
$change.ResourceRecordSet.ResourceRecords.Add(@{Value="$new_ipv4"})

$params = @{
  HostedZoneId=$hosted_zone
  ChangeBatch_Comment="Update DNS to $new_ipv4"
  ChangeBatch_Change=$change
}

Edit-R53ResourceRecordSet @params
```
