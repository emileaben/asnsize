#!/usr/bin/env perl
use strict;
use warnings;
use YAML::Syck qw(DumpFile Dump);
use Socket qw(inet_aton);

my $d = {};
open (F,$ARGV[0]) or die;
while (<F>) {
   if (/^BLOB:/) {
      chomp();
# BLOB: |aggr|94.235.192.0/19|20978|
      my (undef,undef,$pfx,$as) = split(/\|/,$_);
      my ($ip,$len)  = split(/\//, $pfx);
      my $bin_full = unpack('B*', inet_aton( $ip ));
      my $bin_part = substr($bin_full, 0, $len);
     
      my $node = $d; 
      foreach my $bit (split(//,$bin_part)) {
         if ( $node->{$bit} ) {
            $node = $node->{$bit};
         } else {
            $node = $node->{$bit} = {};
         }
      }
      $node->{_bin} = $bin_part;
      $node->{_pfx} = $pfx;
      $node->{_len} = $len;
      $node->{_size} = 2**(32-$len);
      push @{ $node->{_as} }, $as;
   };
}
close F;

my $node = $d;
my $c;
traverse($node,'_');

sub traverse {
   my ($node,$parentas) = @_;
   my $myas = $parentas;
   if ( $node->{_as} ) {
      my %seen;
      $myas =  join("|", grep { ! $seen{$_}++ } @{ $node->{_as} } );
      #THIS DOESN"T WORK ON DUPLICATE RIS DATA $myas = join("|", @{ $node->{_as} } );
      if ($parentas ne $myas) {
         # if ($parentas eq '_' && $node->{_len} <= 8 ) {
            #print "PP $parentas $myas\n";
         #} else {
            # substract this pfx size from parent
            $c->{$parentas}{size} -= $node->{_size};
            $c->{$myas}{size} += $node->{_size};
         #}
      } else {
            $c->{$myas}{te_slots}++;
      }
      $c->{$myas}{slots}++;
   } 
   foreach my $bit (0, 1) {
      traverse( $node->{$bit}, $myas ) if ( $node->{$bit} );
   }
}

for my $as (sort {$c->{$b}{size} <=> $c->{$a}{size} } keys %$c) {
   next unless($as);
   print join("\t", 
      $as,
      $c->{$as}{size} ? $c->{$as}{size} : 'n/a',
      $c->{$as}{slots} ? $c->{$as}{slots} : 'n/a',
      $c->{$as}{te_slots} ? $c->{$as}{te_slots} : 0
   ) . "\n";
}
#DumpFile("$ARGV[0].yaml", $d);
#DumpFile("$ARGV[0].sizes.yaml", $c);
