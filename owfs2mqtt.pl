#!/usr/bin/perl

use strict;
use warnings;
use OWNet;
use AnyEvent::MQTT;
use AnyEvent::DateTime::Cron;

# File-scope variables
our $mqtt;
our $owserver;

sub owfs_callback {
    my $dirlist = $owserver->dir( '/' );
    my @dirs = split ( /,/, $dirlist );
    foreach my $device ( @dirs ) {
        if ( $device =~ '^/28\.' ) {
	    my $temp = $owserver->read( $device."/temperature" );
	    if ( defined $temp ) {
                my $topic = 'raw/owfs'.$device.'/temperature';
                # Publish MQTT message to Broker
                my $cv_mqtt = $mqtt->publish( topic => $topic,
	                                      message => $temp );
	        
	    }
	}
    }
}

# Connect to the MQTT Broker
$mqtt = AnyEvent::MQTT->new( host => 'mqtt',
			     client_id => 'owfs2mqtt',
                             user_name => 'USERNAME',
                             password => 'PASSWORD' );

# Connect to the One-Wire server
$owserver = OWNet->new( );

# Create the cron object
my $cron = AnyEvent::DateTime::Cron->new( );

# Add the cron timer
$cron->add( '*/5 * * * *', \&owfs_callback );

# Start cron and run the event loop
my $cv = $cron->start( );
$cv->recv;

