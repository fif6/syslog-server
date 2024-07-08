#!/usr/bin/perl -w


BEGIN {
	use FindBin;
	unshift(@INC, "${FindBin::RealBin}/modules"); # add custom Modules path at first of search in @INC
};


#BEGIN {
#	use File::Basename;
#	push (@INC, dirname(__FILE__) );
#};


use warnings;
use strict;
use Net::Syslogd;
use Switch;
#use Time::localtime;
use Data::Dumper;
use JSON;
#use Encode;
#use encoding 'utf8';
require HttpAPI;


use constant API_TOKEN		=> 'passwdstring';
use constant API_URL		=> 'http://api.server.host:88/rsyslog.php';
use constant SERVER_ID		=> '7.6.5.4'; # Server IP
use constant BIND_ADDR		=> '1.2.3.4'; #
use constant BIND_PORT		=> 514;
use constant DEBUG		=> 1;


my $syslogd = Net::Syslogd->new('IPv4', BIND_ADDR, BIND_PORT, 5) or die "Error creating Syslogd listener: ", Net::Syslogd->error;
my %http_api_reply = ();

my $http_api = B2HttpAPI->new(API_URL, API_TOKEN);
my $json_data;

while (1) {
	my $message = $syslogd->get_message();
	#print Dumper $message;
	
	if ( !defined($message) ) {
		printf "$0: %s\n", Net::Syslogd->error;
		exit 1;
	} elsif ($message == 0) {
		next;
	}

	if ( !defined($message->process_message()) ) {
		printf "$0: %s\n", Net::Syslogd->error;
	} else {
		printf "%s:%i\t%s\t%s\t\t%s\t%s\t%s\n",
		$message->remoteaddr,
		$message->remoteport,
		#$message->facility ."(",$message->facility(1).")",
		#$message->severity ."(",$message->severity(1).")",
		$message->facility,
		$message->severity,
		$message->time,
		$message->hostname,
		$message->message if DEBUG > 0;
		
		$json_data = to_json({
			'remoteaddr' => $message->remoteaddr,
			'server_id' => SERVER_ID,
			'facility' => $message->facility(1),
			'severity' => $message->severity(1),
			'hostname' => $message->hostname,
			'message' => $message->message
		});


		%http_api_reply = %{$http_api->query( ['data' => $json_data] )};
		#if ( DEBUG ) {
		#	print Dumper \%http_api_reply;
		#	print "----------------------------------------------------\n";
		#}
	}
}

