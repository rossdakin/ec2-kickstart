#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;

my $instance = "i-XXXXXXXX";
my $vol_name = "MyVolume";
my $vol_id = "vol-XXXXXXXX";
my $snap_name = "$vol_name (backup)";
my $snap_desc = "Pre-attachment backup (" . basename($0) . ")";

###############################################################################

my ($cmd, $out);

my $now = `date`;
print "---\n$now";


# create snapshot of volume
print "Creating snapshot of volume ($vol_id)...\n";
$cmd = join(' ',
            "aws ec2 create-snapshot",
            "--volume-id $vol_id",
            "--description '$snap_desc'");

$out = `$cmd` or die "Failed to create snapshot of volume $vol_id";
$out =~ m/"SnapshotId": "(.+)"/;
my $snap = $1 or die "Could not determine snapshot ID: $out";


# give new snapshot a name
print "Giving new snapshot ($snap) a name: '$snap_name'...\n";
$cmd = join(' ',
            "aws ec2 create-tags",
            "--resources $snap",
            "--tags Key=Name,Value='$snap_name'");

$out = `$cmd`;
die "Failed to give snapshot $snap the name '$snap_name': $out" if $out;


# start the sleeping instance
print "Starting instance $instance...\n";
$out = `aws ec2 start-instances --instance-ids $instance` or die "Couldn't start instance $instance: $out";


# success
print "Done.\n";
