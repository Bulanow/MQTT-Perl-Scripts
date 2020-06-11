#!/usr/bin/perl

use strict;
use warnings;
use JSON;
use LWP::Authen::OAuth2;
use AnyEvent::MQTT;
use AnyEvent::DateTime::Cron;

# File-scope variables
our $filename = $ENV{ "HOME" }.'/.NIBEUplinkAPI/token.json';
our $oauth2;
our $mqtt;

# Subroutine to save new OAuth2 token when it changes
sub save_tokens {
    my $token_string = shift;
    open( my $fh, '>', $filename );
    print $fh $token_string;
    close $fh;
}

# Subroutine for AnyEvent Callbacks
sub nibe_callback {
    my $url;
    my $response;
    my $decoded;
    my $hashref;

    # Get the Systems for this Account
    $url = "https://api.nibeuplink.com/api/v1/systems";
    $response = $oauth2->get( $url );
    if ( $response->is_error ) { print $response->error_as_HTML }
    if ( $response->is_success ) {
	$decoded = decode_json( $response->content );
	# Expect $decoded to be a Reference to a Hash
	my $objects = $decoded->{ 'objects' };
	# Expect $objects to be a Reference to an Array of Hashes
	for my $hashref ( @ { $objects } ) {
	    my $system = $hashref->{ 'systemId' };

	    # Get the Categories for this System
	    $url = "https://api.nibeuplink.com/api/v1/systems/$system/serviceinfo/categories";
	    $response = $oauth2->get( $url );
	    if ( $response->is_error ) { print $response->error_as_HTML }
	    if ( $response->is_success ) {
		$decoded = decode_json( $response->content );
		# Expect $decoded to be a Reference to an Array of Hashes
		for my $hashref ( @ { $decoded } ) {
		    my $category = $hashref->{ 'categoryId' };

		    # Get the Parameters for this Category
		    $url = "https://api.nibeuplink.com/api/v1/systems/$system/serviceinfo/categories/status?categoryId=$category";
		    $response = $oauth2->get( $url );
		    if ( $response->is_error ) { print $response->error_as_HTML }
		    if ( $response->is_success ) {
			$decoded = decode_json( $response->content );
			# Expect $decoded to be a Reference to an Array of Hashes
			for my $hashref ( @ { $decoded } ) {
			    # Crude way to spot which Parameters are Temperatures
			    if ( $hashref->{ 'unit' } =~ /C$/ ) {
				# Hack to exclude avg. outdoor temp
				if ( $hashref->{ 'name' } ne '40067' ) {
				    my $designation = $hashref->{ 'designation' };
				    my $rawvalue = $hashref->{ 'rawValue' };
				    my $floatvalue = $rawvalue / 10;
				    my $topic = "raw/nibeuplink/$system/$designation/temperature";
				    # Publish MQTT message to Broker
				    my $cv_mqtt = $mqtt->publish( topic => $topic,
								  message => $floatvalue );
				}
			    # Crude way to spot which Parameters are Percentages
			    } elsif ( $hashref->{ 'unit' } eq '%' ) {
				    my $designation = $hashref->{ 'designation' };
				    my $rawvalue = $hashref->{ 'rawValue' };
				    # Already full-scale, no need to /10
				    my $floatvalue = $rawvalue;
				    my $topic = "raw/nibeuplink/$system/$designation/percentage";
				    # Publish MQTT message to Broker
				    my $cv_mqtt = $mqtt->publish( topic => $topic,
								  message => $floatvalue );
			    # Crude way to spot which Parameters are Degree Minutes
			    } elsif ( $hashref->{ 'unit' } eq 'DM' ) {
				    my $parameterid = $hashref->{ 'parameterId' };
				    my $rawvalue = $hashref->{ 'rawValue' };
				    my $floatvalue = $rawvalue / 10;
				    my $topic = "raw/nibeuplink/$system/$parameterid/degreeminutes";
				    # Publish MQTT message to Broker
				    my $cv_mqtt = $mqtt->publish( topic => $topic,
								  message => $floatvalue );
			    # Crude way to spot which Parameters are Hours
			    } elsif ( $hashref->{ 'unit' } eq 'h' ) {
				    my $parameterid = $hashref->{ 'parameterId' };
				    my $rawvalue = $hashref->{ 'rawValue' };
				    # Already full-scale, no need to /10
				    my $floatvalue = $rawvalue;
				    my $topic = "raw/nibeuplink/$system/$parameterid/hours";
				    # Publish MQTT message to Broker
				    my $cv_mqtt = $mqtt->publish( topic => $topic,
								  message => $floatvalue );
			    # Crude way to spot which Parameters are kilo Watts
			    } elsif ( $hashref->{ 'unit' } eq 'kW' ) {
				    my $parameterid = $hashref->{ 'parameterId' };
				    my $rawvalue = $hashref->{ 'rawValue' };
				    my $floatvalue = $rawvalue / 100;
				    my $topic = "raw/nibeuplink/$system/$parameterid/kilowatts";
				    # Publish MQTT message to Broker
				    my $cv_mqtt = $mqtt->publish( topic => $topic,
								  message => $floatvalue );
			    }
			}
		    }
		}
	    }
	}
    }
}

# Main Program
my $token_string;

# Connect to the MQTT Broker
$mqtt = AnyEvent::MQTT->new( host => 'mqtt',
			     client_id => 'nibe2mqtt',
                             user_name => 'USERNAME',
                             password => 'PASSWORD' );

# Read saved token_string from file
open( my $fh, '<', $filename )
    or die "Could not open file $filename: $!";
$token_string = <$fh>;
chomp $token_string;
close( $fh );

# Construct the OAuth2 object
$oauth2 = LWP::Authen::OAuth2->new(
    service_provider => "NIBEUplink",
    client_id => "SECRET",
    client_secret => 'SECRET',
    redirect_uri => "https://www.marshflattsfarm.org.uk/openhab/oauth2callback",
    token_string => $token_string,
    save_tokens => \&save_tokens
);

# Create the cron object
my $cron = AnyEvent::DateTime::Cron->new( );

# Add the cron timer
$cron->add( '*/2 * * * *', \&nibe_callback );

# Start cron and run the event loop
my $cv = $cron->start( );
$cv->recv;

