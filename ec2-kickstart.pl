#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;

my $instance = "i-XXXXXXXX";
my $host_name = "my.public.host.name";
my $hosted_zone = "/hostedzone/XXXXXXXXXXXXXX";
my $dns_ttl = 60; # seconds

my $vol_name = "MyVolume";
my $vol_id = "vol-XXXXXXXX";
my $snap_name = "$vol_name (backup)";
my $snap_desc = "Pre-attachment backup (" . basename($0) . ")";

###############################################################################

my ($cmd, $out);

print "---\n";


# start the sleeping instance
print "Starting instance $instance...\n";
$out = `aws ec2 start-instances --instance-ids $instance` or die "Couldn't start instance $instance: $out";


# get instance DNS name
print "Getting public IP address of instance ($instance)...\n";
my $ip = undef;
while(!$ip) {
    sleep 1;
    $out = `aws ec2 describe-instances --instance-ids $instance`;
    $out =~ m/"PublicIpAddress": "(.+)"/;
    $ip = $1;
}

# update DNS (Route53)
print "Updating DNS (pointing $host_name to $ip)...\n";
my $change_batch = "'\
          {\
            \"Comment\": \"Updating $host_name to $ip\",\
            \"Changes\": [\
              {\
                \"Action\": \"UPSERT\",\
                \"ResourceRecordSet\": {\
                  \"Name\": \"$host_name\",\
                  \"Type\": \"A\",\
                  \"TTL\": $dns_ttl,\
                  \"ResourceRecords\": [\
                    {\
                      \"Value\": \"$ip\"\
                    }\
                  ]\
                }\
              }\
            ]\
          }\
'";
$cmd = join(' ',
            "aws route53 change-resource-record-sets",
            "--hosted-zone-id $hosted_zone",
            "--change-batch $change_batch");

`$cmd`;


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

$out = `$cmd` or die "Failed to give snapshot $snap the name '$snap_name': $out";


# success
print "Done.\n";
