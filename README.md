ec2-kickstart
=============

Perl script for kickstarting an EC2 instance.

_The following is a partial excerpt from my 8/25/11 blog post, which has more context (http://www.dakindesign.com/blog/windows-workstations-in-amazon-ec2/)_

Replace the “xxx” in the variables near the top, then run it. This assumes you:
* Have the EC2 API tools (get them from Amazon’s site)
* Have configured your system such that the EC2 API tools work (e.g. I had to add “export JAVA_HOME=/System/Library/Frameworks/JavaVM.framework/Versions/CurrentJDK/Home” to my .bash_profile)
* Have generated, downloaded, and exported EC2_PRIVATE_KEY and EC2_CERT variables pointing to your Amazon X.509 certificate and private key.

You’ll notice some domain name and IP address stuff in the Perl script. Just comment it out if you don’t have a domain name that you want to point to your windows instance. However, it’s useful! To use this:
1. Allocate an Amazon Elastic IP Address
2. Point a domain name to this IP address

Now when you run the Perl file:
* An instance will be started from your AMI
* Your EBS volume will be attached to the instance (and a snapshot will be taken)
* Your elastic IP address will be associated with the instance

Remote Desktop to your Windows address and you’re all set! Shut down the computer when you’re done, and all clean-up will happen automatically (instance termination, EBS volume detachment, elastic IP disassociation).

NOTE: the Perl script specifies that your instance should terminate (rather than stop) when you shut down Windows internally. That allows us to tear it all down by just using the Windows regular shutdown method, instead of using the Amazon web interface or API.