#!/usr/bin/perl
use strict;
use warnings;
use Fcntl qw(:flock);

open(my $script_fh, '<', $0)
   or die("No se pudo abrir el archivo: $!\n");

unless (flock($script_fh, LOCK_EX|LOCK_NB)) {
    print "$0 ya se encuentra en ejecución.\n";
    exit(1);
}

print "ejecutando...\n";
sleep(15);
print "Fin del programa\n";