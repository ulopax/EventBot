#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 6;
use File::Slurp qw(slurp);
use Data::Dumper;

use_ok('EventBot::MailParser') or die;

# Test new events:
{
    my $newevent_text = slurp('t/newevent.txt');
    my $parser = EventBot::MailParser->new;
    $parser->parse($newevent_text);
    diag(Dumper($parser->commands));
    is_deeply(
        $parser->commands,
        [ {
            type => 'newevent',
            # TODO
        } ],
        "Locate new event in email"
    );
}

# Test attendance to an event:
{
    my $attend_text = slurp('t/attend.txt');
    my $parser = EventBot::MailParser->new;
    $parser->parse($attend_text);
    diag(Dumper($parser->commands));
    is_deeply(
        $parser->commands,
        [{
            type => 'attend',
            mode => '+',
            name => 'Wintrmute (blah)',
            event => 123,
        }],
        "Found attendance command in plaintext email"
    );
}

# Test attendance to an event, in a MIME-encoded email:
{
    my $attend_mime = slurp('t/attend_mime.txt');
    my $parser = EventBot::MailParser->new;
    $parser->parse($attend_mime);
    diag(Dumper($parser->commands));
    is_deeply(
        $parser->commands,
        [{
            type => 'attend',
            mode => '+',
            name => 'Simon C',
            event => 205,
        }],
        "Found attendance command in MIME encoded email"
    );
}

# Test attendance to an event, in a multi-part html email:
{
    my $attend_mime = slurp('t/attend_html.txt');
    my $parser = EventBot::MailParser->new;
    $parser->parse($attend_mime);
    diag(Dumper($parser->commands));
    is_deeply(
        $parser->commands,
        [{
            type => 'attend',
            mode => '-',
            name => 'Wintrmute (testing HTML emails)',
            event => 204,
        }],
        "Found attendance command in multi-part HTML email"
    );
}

# Test a vote:
{
    my $attend_mime = slurp('t/vote.txt');
    my $parser = EventBot::MailParser->new;
    $parser->parse($attend_mime);
    diag(Dumper($parser->commands));
    is_deeply(
        $parser->commands,
        [{
            type => 'vote',
            votes => [qw(A B C E)],
        }],
        "Found votes in plaintext email"
    );
}
