#!/usr/bin/perl
#
#    This script calculates the size of the referral response
#    from root servers and compares with the requirements from
#    IANA (https://www.iana.org/help/nameserver-requirements)
#
#    Use:
#        respsize-iana.pl [-v] TLD fqdn_ns1 fqdn_ns2 ...
#    
#    Author: Hugo Salgado <hugo@nic.cl>
#
#    Based on "respsize.pl" script from
#    draft-ietf-dnsop-respsize-15 IETF draft, authored by P.Vixie,
#    A.Kato and J.Abley.
#    Copyright (c) 2014 IETF Trust and the persons identified as the
#    document authors.  All rights reserved.
#    Redistribution and use in source and binary forms, with or
#    without modification, is permitted pursuant to, and subject to
#    the license terms contained in, the Simplified BSD License set
#    forth in Section 4.c of the IETF Trust’s Legal Provisions
#    Relating to IETF Documents (http://trustee.ietf.org/license-info).
#
use strict;
use warnings;

# This magic number is IANA maximum size (512), less headers,
# question section with qname 255, and two glues (A + AAAA)
my $REST = 197;

# If you happen to have NS names not in-bailiwick, you have
# more room (A+AAAA glues)
my $REST_NB = $REST + 44;

my %namedb;
my ($n_ns, $sz_ptr, $nslen, $bail) = (0, 2, 0, 1);

my $verbose;
if ($ARGV[0] eq '-v') {
    $verbose = 1;
    shift @ARGV;
}

my $tld = shift @ARGV;
$tld =~ s/\.$//;

foreach my $name (@ARGV) {
    $n_ns++;
    my $len = server_name_len($name);
    print "\t$name requires $len bytes\n" if $verbose;
    $nslen += $len;
}
print "\tNumber of NS: $n_ns\n" if $verbose;
print "\tTLD have NS not in-bailiwick\n" if !$bail and $verbose;

my $left = ($bail ? $REST : $REST_NB) - ($nslen + 12*$n_ns);
if ($left >= 0) {
    print "OK -> You have $left bytes left\n";
}
else {
    $left *= -1;
    print "BAD -> You have $left bytes more than maximum!\n";
}

sub server_name_len {
    my ($name) = @_;
    my (@labels, $len, $n, $suffix);

    $name =~ tr/A-Z/a-z/;
    @labels = split(/\./, $name);
    $len = length(join('.', @labels)) + 2;
    for ($n = 0; $#labels >= 0; $n++, shift @labels) {
        $suffix = join('.', @labels);
        return length($name) - length($suffix) + $sz_ptr
            if (defined($namedb{$suffix}));
        $namedb{$suffix} = 1;
        if ($#labels == 0) {
            $bail = 0 if $suffix ne $tld;
        }
    }
    return $len;
}

