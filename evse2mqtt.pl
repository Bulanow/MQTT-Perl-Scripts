#!/usr/bin/perl
#
# Copyright (c) 2020 David M Brooke, davidmbrooke@users.sourceforge.net
#
#
use strict;
use warnings;
use XML::LibXML;
use LWP::UserAgent;
use AnyEvent::MQTT;
use AnyEvent::DateTime::Cron;

# File-scope variables
our $mqtt;

sub evse_callback {
    my $useragent;
    my $response;
    my $meterReading;

    # Construct the UserAgent object
    $useragent = LWP::UserAgent->new( );

    # Get the Charge Info summary
    $response = $useragent->get( 'http://192.168.0.1/services/chargePointsInterface/chargeInfo.xml' );
    if ( $response->is_error ) { print $response->error_as_HTML }
    if ( $response->is_success ) {
	my $dom = XML::LibXML->load_xml( string => $response->content );
	foreach my $node ( $dom->findnodes( '//activeEnergy' ) ) {
	    my @fields = split( /\./, $node->to_literal( ) );
	    $meterReading = $fields[0];
	    if ( defined $meterReading ) {
	    	my $topic = 'raw/evse/plug1/activeEnergy';
	    	# Publish MQTT message to Broker
	    	my $cv_mqtt = $mqtt->publish( topic => $topic, message => $meterReading );
	    }
	}
    }
}

# Connect to the MQTT Broker
$mqtt = AnyEvent::MQTT->new( host => 'mqtt',
                             client_id => 'evse2mqtt',
                             user_name => 'USERNAME',
                             password => 'PASSWORD',
			     on_error => sub { print "MQTT Error\n" } );

# Create the cron object
my $cron = AnyEvent::DateTime::Cron->new( );

# Add the cron timer
$cron->add( '*/5 * * * *', \&evse_callback );

# Start cron and run the event loop
my $cv = $cron->start( );
$cv->recv;

