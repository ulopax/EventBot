#!/usr/bin/env perl
use strict;
use warnings;
use EventBot::Geocode;
use EventBot::Schema;

# Script to geocode everything in the DB..
# TODO: Adjust to only geocode un-geocoded pubs or individual IDs or something?

my $schema = EventBot::Schema->connect('dbi:Pg:dbname=eventbot') or die;
my $g = EventBot::Geocode->new;

my $pubs = $schema->resultset('Pubs')->search({}, { order_by => 'id' });

while (my $pub = $pubs->next) {
    my $loc = eval {
        $g->address($pub->street_address);
    };
    if ($@) {
        print sprintf('Failed to geocode pub %s (%d) at %s: %s%s',
            $pub->name, $pub->id,
            $pub->street_address,
            $@, "\n"
        );
        next;
    }
    $pub->update($loc);
    print "Geocoded " . $pub->name . "\n";
}

