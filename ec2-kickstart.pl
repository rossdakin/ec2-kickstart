#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use Socket;

my $ami = "ami-XXXXXXXX";
my $group = "MY-GROUP-NAME";
my $keypair = "MY-KEY-NAME";
my $zone = "us-east-1b";
my $type = "m1.small";
my $host_name = "my.public.host.name";
my $vol_name = "MyVolume";
my $snap_name = "$vol_name (backup)";
my $snap_desc = "Pre-attachment backup (" . basename($0) . ")";

###############################################################################

my ($cmd, $out);

print "---\n";

# run instance
print "Starting new instance from AMI ($ami)...\n";

$cmd = join(' ',
            "ec2-run-instances",
            "$ami",
            "-g $group",
            "-n 1",
            "-k $keypair",
            "-t $type",
            "-z $zone",
            "--instance-initiated-shutdown-behavior terminate");

$out = `$cmd` or die "Failed to start an instance of $ami";

$out =~ m/INSTANCE\t(i-\w+)/;
my $instance = $1 or die "Could not get new instance ID";


# wait for instance to be "running"
print "Waiting 30 seconds for new instance ($instance) to be running...\n";
sleep(30);


# get IP from host name
print "Resolving host name ($host_name) to IP address...\n";

my $ip = inet_ntoa(inet_aton($host_name)) or die "Couldn't resolve $host_name";


# associate
print "Associating elastic IP address ($ip) with instance ($instance)...\n";
$cmd = join(' ',
            "ec2-associate-address",
            "-i $instance",
            "$ip");

$out = `$cmd` or die "Failed to associate $ip";


# get volume ID from name
print "Fetching description of EBS volume ($vol_name)...\n";

$out = `ec2-describe-volumes -F tag:Name=$vol_name`;
$out =~ m/VOLUME\t(vol-\w+)\t/;

my $vol = $1 or die "Could not determine EBS volume ID from name ($vol_name)";


# detach from existing instance
if ($out =~ m/ATTACHMENT(?:\t[^\t]*){3}\t(\w+)\t/) {
    my $state = $1;

    print "  Already attached to another instance...\n";

    # detach if attaching/attached
    `ec2-detach-volume $vol` if ($1 =~ m/attach/);

    # wait for attachment to go away
    my $ready = 0;
    do {
        sleep(3);

        print "  State: $state\n";

        $out = `ec2-describe-volumes -F tag:Name=$vol_name`;

        if ($out =~ m/ATTACHMENT(?:\t[^\t]*){3}\t(\w+)\t/) {
            $state = $1;
        } else {
            $ready = 1;
        }
    } while (!$ready);
}

# create snapshot of volume before attaching it
print "Creating snapshot of volume ($vol)...\n";
$cmd = join(' ',
            "ec2-create-snapshot",
            "$vol",
            "-d '$snap_desc'");

$out = `$cmd` or die "Failed to create snapshot of volume $vol";
$out =~ m/SNAPSHOT\t(snap-\w+)\t/;

my $snap = $1 or die "Could not determine snapshot ID";


# give new snapshot a name
print "Giving new snapshot ($snap) a name: '$snap_name'...\n";
$cmd = join(' ',
            "ec2-create-tags",
            "$snap",
            "--tag Name='$snap_name'");

$out = `$cmd` or die "Failed to give snapshot $snap the name '$snap_name'";


# attach
print "Attaching volume ($vol) to instance ($instance)...\n";
$cmd = join(' ',
            "ec2-attach-volume",
            "$vol",
            "-i $instance",
            "-d xvdf");

$out = `$cmd` or die "Failed to attach volume $vol";


# success
print "Done.\n";
