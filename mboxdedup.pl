#!/usr/bin/perl

# Simple program to remove duplicate email messages
# from an mbox file. This program only looks at the content
# of the message for uniqueness, not entire message with the headers.
# There is no file locking, use this program on a backup 
# of your mbox file.

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

#grab file names from the program parameters.
#and do some error checking.
my $from = shift @ARGV;
my $keep = shift @ARGV;
my $junk = shift @ARGV;

if ( $#ARGV != -1 || ! defined $junk ) {
    print STDERR "usage: $0 original clean junk\n";
    exit(-1);
}

my (%uniq, $msg);
my ($head, $body);
my $i = 0;
my $dups = 0;
my $nulls = 0;

$|++;

open (my $IN,  "<$from") || die "cannot open $from: $!";
open (my $KEEP, ">$keep")   || die "cannot open $keep $!";
open (my $JUNK, ">$junk")   || die "cannot open $junk $!";
my $fline = <$IN>;
print $KEEP $fline;
while(<$IN>) {
    #emails in mbox files always begin with ^From 
    #when /^From / is matched, process the previous message
    #then start on this message
    if(m/^From /) {
	next if (!defined $msg || $msg eq "");
	#increment the counter for a status report
	$i++;
	#print a status report if necessary.
	#I like to do it this way
	print '.' if(($i % 50) == 0);
	if(($i % 1000) == 0) {
	    print " $i, $dups duplicates, $nulls null messages found\n" 
	}
	#since evolution can give different headers on the same message,
	#only hash the body of the message, and use that to compare to other
	#emails. The entire message will be stored in the hash though.
	($head, $body) = split /\n\n/, $msg, 2;
	#standard perl technique for removing duplicates, using hashes and 
	#md5 files.
	if ( ! defined $body ) {
	    $nulls++;
	    print $JUNK $msg;
	} else {
	    my $md5 = md5_hex($body);
	    if ( !defined $uniq{$md5} ) {
		$uniq{$md5} = 1;
		print $KEEP $msg;
	    } else {
		print $JUNK $msg;
		$dups++;
	    }
	}
	
	#done processing the previous message, start the next message
	$msg = $_;
    } else {
	#current line didn't match /^From / so this line is part of the
	#middle of the current message. Just tack it on to the end.
	$msg .= $_;
    }
}
$i++;
print "Done, $i messages, $dups duplicates, $nulls nulls\n";
