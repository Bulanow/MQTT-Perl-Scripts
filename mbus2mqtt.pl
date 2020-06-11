#!/usr/bin/perl
#
# Copyright (c) 2017 David M Brooke, davidmbrooke@users.sourceforge.net
#
#
use strict;
use warnings;
use XML::LibXML;
use AnyEvent::MQTT;
use AnyEvent::DateTime::Cron;

# File-scope variables
our $mqtt;
our $gshp_power;

sub mbus_callback {

    my $retcode;
    my $value1 = 0;
    my $value2 = 0;
    my $value3 = 0;
    my $value4 = 0;

    # Meter #1 (Itron Cyble, cold water main)
    # Get a retcode of 0 for successful communication, 256 for "Failed to receive M-Bus response frame."
    $retcode = 256;
    while ( $retcode == 256 ) {
        my $xmlresponse = `mbus-serial-request-data -b 2400 /dev/ttyUSB0 1`;
        $retcode = $?;
	if ( defined $xmlresponse && length( $xmlresponse ) > 0 ) {
	    my $dom = XML::LibXML->load_xml( string => (\$xmlresponse) );
	    my $DataRecords = $dom->findnodes( '/MBusData/DataRecord' );
	    foreach my $DataRecord ( $DataRecords->get_nodelist ) {
		if ( $DataRecord->hasAttributes ) {
		    foreach my $attribute ( $DataRecord->attributes ) {
			if ( $attribute->getValue == 4 ) {
			    $value1 = $DataRecord->findvalue( './Value' );
			    if ( defined $value1 ) {
				my $topic = 'raw/m-bus/001/water';
				# Publish MQTT message to Broker
				my $cv_mqtt = $mqtt->publish( topic => $topic,
							      message => $value1 );
			    }
			}
		    }
		}
	    }
	}
    }

    # Meter #2 (Itron Cyble, RWH water main)
    # Get a retcode of 0 for successful communication, 256 for "Failed to receive M-Bus response frame."
    $retcode = 256;
    while ( $retcode == 256 ) {
        my $xmlresponse = `mbus-serial-request-data -b 2400 /dev/ttyUSB0 2`;
        $retcode = $?;
	if ( defined $xmlresponse && length( $xmlresponse ) > 0 ) {
	    my $dom = XML::LibXML->load_xml( string => (\$xmlresponse) );
	    my $DataRecords = $dom->findnodes( '/MBusData/DataRecord' );
	    foreach my $DataRecord ( $DataRecords->get_nodelist ) {
		if ( $DataRecord->hasAttributes ) {
		    foreach my $attribute ( $DataRecord->attributes ) {
			if ( $attribute->getValue == 4 ) {
			    $value2 = $DataRecord->findvalue( './Value' );
			    if ( defined $value2 ) {
				my $topic = 'raw/m-bus/002/water';
				# Publish MQTT message to Broker
				my $cv_mqtt = $mqtt->publish( topic => $topic,
							      message => $value2 );
			    }
			}
		    }
		}
	    }
	}
    }

    # Meter #3 (Itron Cyble, hot water)
    # Get a retcode of 0 for successful communication, 256 for "Failed to receive M-Bus response frame."
    $retcode = 256;
    while ( $retcode == 256 ) {
        my $xmlresponse = `mbus-serial-request-data -b 2400 /dev/ttyUSB0 3`;
        $retcode = $?;
	if ( defined $xmlresponse && length( $xmlresponse ) > 0 ) {
	    my $dom = XML::LibXML->load_xml( string => (\$xmlresponse) );
	    my $DataRecords = $dom->findnodes( '/MBusData/DataRecord' );
	    foreach my $DataRecord ( $DataRecords->get_nodelist ) {
		if ( $DataRecord->hasAttributes ) {
		    foreach my $attribute ( $DataRecord->attributes ) {
			if ( $attribute->getValue == 4 ) {
			    $value3 = $DataRecord->findvalue( './Value' );
			    if ( defined $value3 ) {
				my $topic = 'raw/m-bus/003/water';
				# Publish MQTT message to Broker
				my $cv_mqtt = $mqtt->publish( topic => $topic,
							      message => $value3 );
			    }
			}
		    }
		}
	    }
	}
    }

    # Meter #4 (Virtual meter for #1 - #3, i.e. net cold usage, subtracting hot)
    $value4 = $value1 - $value3;
    my $topic = 'raw/m-bus/004/water';
    # Publish MQTT message to Broker
    my $cv_mqtt = $mqtt->publish( topic => $topic,
				  message => $value4 );

    # Meter #11 (Relay Padpuls M2C Channel 1, MVHR Electricity Consumption)
    # Get a retcode of 0 for successful communication, 256 for "Failed to receive M-Bus response frame."
    $retcode = 256;
    while ( $retcode == 256 ) {
        my $xmlresponse = `mbus-serial-request-data -b 2400 /dev/ttyUSB0 11`;
        $retcode = $?;
	if ( defined $xmlresponse && length( $xmlresponse ) > 0 ) {
	    my $dom = XML::LibXML->load_xml( string => (\$xmlresponse) );
	    my $DataRecords = $dom->findnodes( '/MBusData/DataRecord' );
	    foreach my $DataRecord ( $DataRecords->get_nodelist ) {
		if ( $DataRecord->hasAttributes ) {
		    foreach my $attribute ( $DataRecord->attributes ) {
			if ( $attribute->getValue == 0 ) {
			    $value1 = $DataRecord->findvalue( './Value' );
			    if ( defined $value1 ) {
				# Convert from Wh to kWh
				$value2 = $value1/1000;
				my $topic = 'raw/m-bus/011/electricity';
				# Publish MQTT message to Broker
				my $cv_mqtt = $mqtt->publish( topic => $topic,
							      message => $value2 );
			    }
			}
		    }
		}
	    }
	}
    }

    # Meter #12 (Relay Padpuls M2C Channel 2, Electricity Generation)
    # Get a retcode of 0 for successful communication, 256 for "Failed to receive M-Bus response frame."
    $retcode = 256;
    while ( $retcode == 256 ) {
        my $xmlresponse = `mbus-serial-request-data -b 2400 /dev/ttyUSB0 12`;
        $retcode = $?;
	if ( defined $xmlresponse && length( $xmlresponse ) > 0 ) {
	    my $dom = XML::LibXML->load_xml( string => (\$xmlresponse) );
	    my $DataRecords = $dom->findnodes( '/MBusData/DataRecord' );
	    foreach my $DataRecord ( $DataRecords->get_nodelist ) {
		if ( $DataRecord->hasAttributes ) {
		    foreach my $attribute ( $DataRecord->attributes ) {
			if ( $attribute->getValue == 0 ) {
			    $value1 = $DataRecord->findvalue( './Value' );
			    if ( defined $value1 ) {
				# Convert from Wh to kWh
				$value2 = $value1/1000;
				my $topic = 'raw/m-bus/012/electricity';
				# Publish MQTT message to Broker
				my $cv_mqtt = $mqtt->publish( topic => $topic,
							      message => $value2 );
			    }
			}
		    }
		}
	    }
	}
    }

    # Meter #13 (Relay Padpuls M1C, Immersion Heater Consumption)
    # Get a retcode of 0 for successful communication, 256 for "Failed to receive M-Bus response frame."
    $retcode = 256;
    while ( $retcode == 256 ) {
        my $xmlresponse = `mbus-serial-request-data -b 2400 /dev/ttyUSB0 13`;
        $retcode = $?;
	if ( defined $xmlresponse && length( $xmlresponse ) > 0 ) {
	    my $dom = XML::LibXML->load_xml( string => (\$xmlresponse) );
	    my $DataRecords = $dom->findnodes( '/MBusData/DataRecord' );
	    foreach my $DataRecord ( $DataRecords->get_nodelist ) {
		if ( $DataRecord->hasAttributes ) {
		    foreach my $attribute ( $DataRecord->attributes ) {
			if ( $attribute->getValue == 0 ) {
			    $value1 = $DataRecord->findvalue( './Value' );
			    if ( defined $value1 ) {
				# Convert from Wh to kWh
				$value2 = $value1/1000;
				my $topic = 'raw/m-bus/013/electricity';
				# Publish MQTT message to Broker
				my $cv_mqtt = $mqtt->publish( topic => $topic,
							      message => $value2 );
			    }
			}
		    }
		}
	    }
	}
    }

    # Meter #112 (Relay Padpuls M1, GSHP Electricity Consumption)
    # (Out-of-numeric-sequence but want up-to-date power input to GSHP to calculate CoP, rather than using the figure from the last run)
    # Get a retcode of 0 for successful communication, 256 for "Failed to receive M-Bus response frame."
    $retcode = 256;
    while ( $retcode == 256 ) {
        my $xmlresponse = `mbus-serial-request-data -b 2400 /dev/ttyUSB0 112`;
        $retcode = $?;
	if ( defined $xmlresponse && length( $xmlresponse ) > 0 ) {
	    my $dom = XML::LibXML->load_xml( string => (\$xmlresponse) );
	    my $DataRecords = $dom->findnodes( '/MBusData/DataRecord' );
	    foreach my $DataRecord ( $DataRecords->get_nodelist ) {
		if ( $DataRecord->hasAttributes ) {
		    foreach my $attribute ( $DataRecord->attributes ) {
			if ( $attribute->getValue == 0 ) {
			    $value1 = $DataRecord->findvalue( './Value' );
			    if ( defined $value1 ) {
				# Convert from Wh to kWh
				$gshp_power = $value1/1000;
				my $topic = 'raw/m-bus/112/electricity';
				# Publish MQTT message to Broker
				my $cv_mqtt = $mqtt->publish( topic => $topic,
							      message => $gshp_power );
			    }
			}
		    }
		}
	    }
	}
    }

    # Meter #90 (Kamstrup Multical 302, central heating)
    # Get a retcode of 0 for successful communication, 256 for "Failed to receive M-Bus response frame."
    $retcode = 256;
    while ( $retcode == 256 ) {
        my $xmlresponse = `mbus-serial-request-data -b 2400 /dev/ttyUSB0 90`;
        $retcode = $?;
	if ( defined $xmlresponse && length( $xmlresponse ) > 0 ) {
	    my $dom = XML::LibXML->load_xml( string => (\$xmlresponse) );
	    my $DataRecords = $dom->findnodes( '/MBusData/DataRecord' );
	    foreach my $DataRecord ( $DataRecords->get_nodelist ) {
		if ( $DataRecord->hasAttributes ) {
		    foreach my $attribute ( $DataRecord->attributes ) {
			if ( $attribute->getValue == 1 ) {
			    $value1 = $DataRecord->findvalue( './Value' );
			    if ( defined $value1 ) {
				my $topic = 'raw/m-bus/090/heat';
				# Publish MQTT message to Broker
				my $cv_mqtt = $mqtt->publish( topic => $topic,
							      message => $value1 );
			    }
			}
			if ( $attribute->getValue == 5 ) {
			    $value1 = $DataRecord->findvalue( './Value' );
			    if ( defined $value1 ) {
				my $topic = 'raw/m-bus/090/volume';
				# Publish MQTT message to Broker
				my $cv_mqtt = $mqtt->publish( topic => $topic,
							      message => $value1 );
			    }
			}
			if ( $attribute->getValue == 8 ) {
			    $value1 = $DataRecord->findvalue( './Value' );
			    if ( defined $value1 ) {
				my $topic = 'raw/m-bus/090/flow/temperature';
				# Publish MQTT message to Broker
				my $cv_mqtt = $mqtt->publish( topic => $topic,
							      message => $value1 );
			    }
			}
			if ( $attribute->getValue == 9 ) {
			    $value1 = $DataRecord->findvalue( './Value' );
			    if ( defined $value1 ) {
				my $topic = 'raw/m-bus/090/return/temperature';
				# Publish MQTT message to Broker
				my $cv_mqtt = $mqtt->publish( topic => $topic,
							      message => $value1 );
			    }
			}
			if ( $attribute->getValue == 10 ) {
			    $value1 = $DataRecord->findvalue( './Value' );
			    if ( defined $value1 ) {
				my $topic = 'raw/m-bus/090/temperature-difference';
				# Publish MQTT message to Broker
				my $cv_mqtt = $mqtt->publish( topic => $topic,
							      message => $value1 );
			    }
			}
			if ( $attribute->getValue == 11 ) {
			    $value1 = $DataRecord->findvalue( './Value' );
			    if ( defined $value1 ) {
				my $topic = 'raw/m-bus/090/power';
				# Publish MQTT message to Broker
				my $cv_mqtt = $mqtt->publish( topic => $topic,
							      message => $value1 );
				# Calculate CoP
				my $output_power = $value1 * 100.0;
				my $cop =  $output_power / $gshp_power;
				$topic = 'raw/m-bus/090/cop';
				# Publish MQTT message to Broker
				$cv_mqtt = $mqtt->publish( topic => $topic,
							      message => $cop );
			    }
			}
			if ( $attribute->getValue == 13 ) {
			    $value1 = $DataRecord->findvalue( './Value' );
			    if ( defined $value1 ) {
				my $topic = 'raw/m-bus/090/flowrate';
				# Publish MQTT message to Broker
				my $cv_mqtt = $mqtt->publish( topic => $topic,
							      message => $value1 );
			    }
			}
		    }
		}
	    }
	}
    }

    # Meter #92 (Kamstrup Multical 302, domestic hot water)
    # Get a retcode of 0 for successful communication, 256 for "Failed to receive M-Bus response frame."
    $retcode = 256;
    while ( $retcode == 256 ) {
        my $xmlresponse = `mbus-serial-request-data -b 2400 /dev/ttyUSB0 92`;
        $retcode = $?;
	if ( defined $xmlresponse && length( $xmlresponse ) > 0 ) {
	    my $dom = XML::LibXML->load_xml( string => (\$xmlresponse) );
	    my $DataRecords = $dom->findnodes( '/MBusData/DataRecord' );
	    foreach my $DataRecord ( $DataRecords->get_nodelist ) {
		if ( $DataRecord->hasAttributes ) {
		    foreach my $attribute ( $DataRecord->attributes ) {
			if ( $attribute->getValue == 1 ) {
			    $value1 = $DataRecord->findvalue( './Value' );
			    if ( defined $value1 ) {
				my $topic = 'raw/m-bus/092/heat';
				# Publish MQTT message to Broker
				my $cv_mqtt = $mqtt->publish( topic => $topic,
							      message => $value1 );
			    }
			}
			if ( $attribute->getValue == 5 ) {
			    $value1 = $DataRecord->findvalue( './Value' );
			    if ( defined $value1 ) {
				my $topic = 'raw/m-bus/092/volume';
				# Publish MQTT message to Broker
				my $cv_mqtt = $mqtt->publish( topic => $topic,
							      message => $value1 );
			    }
			}
			if ( $attribute->getValue == 8 ) {
			    $value1 = $DataRecord->findvalue( './Value' );
			    if ( defined $value1 ) {
				my $topic = 'raw/m-bus/092/flow/temperature';
				# Publish MQTT message to Broker
				my $cv_mqtt = $mqtt->publish( topic => $topic,
							      message => $value1 );
			    }
			}
			if ( $attribute->getValue == 9 ) {
			    $value1 = $DataRecord->findvalue( './Value' );
			    if ( defined $value1 ) {
				my $topic = 'raw/m-bus/092/return/temperature';
				# Publish MQTT message to Broker
				my $cv_mqtt = $mqtt->publish( topic => $topic,
							      message => $value1 );
			    }
			}
			if ( $attribute->getValue == 10 ) {
			    $value1 = $DataRecord->findvalue( './Value' );
			    if ( defined $value1 ) {
				my $topic = 'raw/m-bus/092/temperature-difference';
				# Publish MQTT message to Broker
				my $cv_mqtt = $mqtt->publish( topic => $topic,
							      message => $value1 );
			    }
			}
			if ( $attribute->getValue == 11 ) {
			    $value1 = $DataRecord->findvalue( './Value' );
			    if ( defined $value1 ) {
				my $topic = 'raw/m-bus/092/power';
				# Publish MQTT message to Broker
				my $cv_mqtt = $mqtt->publish( topic => $topic,
							      message => $value1 );
				# Calculate CoP
				my $output_power = $value1 * 100000.0;
				my $cop =  $output_power / $gshp_power;
				$topic = 'raw/m-bus/092/cop';
				# Publish MQTT message to Broker
				$cv_mqtt = $mqtt->publish( topic => $topic,
							      message => $cop );
			    }
			}
			if ( $attribute->getValue == 13 ) {
			    $value1 = $DataRecord->findvalue( './Value' );
			    if ( defined $value1 ) {
				my $topic = 'raw/m-bus/092/flowrate';
				# Publish MQTT message to Broker
				my $cv_mqtt = $mqtt->publish( topic => $topic,
							      message => $value1 );
			    }
			}
		    }
		}
	    }
	}
    }
}


# Connect to the MQTT Broker
$mqtt = AnyEvent::MQTT->new( host => 'mqtt',
                             client_id => 'm-bus2mqtt',
                             user_name => 'USERNAME',
                             password => 'PASSWORD' );

# Create the cron object
my $cron = AnyEvent::DateTime::Cron->new( );

# Add the cron timer
$cron->add( '*/1 * * * *', \&mbus_callback );

# Start cron and run the event loop
my $cv = $cron->start( );
$cv->recv;

