#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;

my $instance = "i-XXXXXXXX";
my $host_name = "my.public.host.name";
my $dns_ttl = 60; # seconds

my $vol_name = "MyVolume";
my $snap_name = "$vol_name (backup)";
my $snap_desc = "Pre-attachment backup (" . basename($0) . ")";

###############################################################################

my ($cmd, $out);

print "---\n";


# start the sleeping instance
print "Starting instance $instance...\n";
`ec2start $instance` or die "Couldn't start instance $instance";


# get instance IP
print "Getting public IP address of new instance ($instance)...\n";

$out = `ec2-describe-instances`;
$out =~ m/INSTANCE\s+$instance(?:\s+\S+){11}\s+(\d+\.\d+\.\d+\.\d+)/;

my $ip = $1 or die "Could not get new instance IP";


# update DNS (Route53) using:
# https://github.com/tkuhlman/cirrus/blob/master/bin/update_host.py
$cmd = join(' ',
            "update_host.py",
            "$host_name",
            "$host_name",
            "-t $dns_ttl",
            "-a $ip");

print `$cmd`;


# get volume ID from name
print "Fetching description of EBS volume ($vol_name)...\n";

$out = `ec2-describe-volumes -F tag:Name=$vol_name`;
$out =~ m/VOLUME\t(vol-\w+)\t/;

my $vol = $1 or die "Could not determine EBS volume ID from name ($vol_name)";


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


# success
print "Done.\n";
