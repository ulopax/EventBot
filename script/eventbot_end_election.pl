#!/usr/local/strategic/perl/bin/perl
use 5.16.0;
use warnings;
use Email::Simple;
use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP qw();
use Getopt::Long;
use DateTime;
use FindBin;
use lib "$FindBin::Bin/../lib";
use EventBot;

my ($help, $sendmail, $election_id);
GetOptions(
    'sendmail' => \$sendmail,
    'election' => \$election_id,
    'help' => \$help,
);

if ($help) {
    print qq{
Start an election.
Params:
  --election=123       Which election to tally up (otherwise latest)
  --sendmail       send a mail to the list.
    };
    exit 1;
}

my $thursday = next_thursday();

my $bot = EventBot->new;
my $schema = $bot->schema;

my $e;
if ($election_id ) {
    $e = $schema->resultset('Elections')->get($election_id)
}
else {
    $e = $schema->resultset('Elections')->latest()
        or die("No current election found!\n");
}

my @results = $e->conclude; # Finish the election and get vote tallies!


my $pub = $e->winner;

# Check if that pub was a special event:
my $birthday = $schema->resultset('SpecialEvents')->search(
    {
        date => $schema->storage->datetime_parser->format_datetime($thursday),
        pub => $pub->id,
        confirmed => 1,
    }
)->next;

my @body;
push @body, 'We have a winner:';
push @body, sprintf('Place: %s (%s)', $pub->name, $pub->region);
if ($pub->name !~ /none of the above/i) {
    push @body, "Date: " . $thursday->dmy;
    push @body, "Time: Evening";
    push @body, 'Address: ' . $pub->street_address;
    if ($pub->info_uri) {
        push @body, 'URL: ' . $pub->info_uri;
    }
}

# Capture event info so far for email to the eventbot..
my $event_body = join("\n", @body);

push @body, '';
if ($birthday) {
    push @body, sprintf('This is %s\'s special event - %s.',
        $birthday->person->name, $birthday->comment
    );
}
push @body, 'If you hate the venue, remember it was endorsed by:';
push @body, join(' and ', map { $_->name } $pub->nominees);

push @body, '';
push @body, 'Vote tallies:';

# Display tallies:
for my $r (@results) {
    push @body, sprintf('%s has a score of %d:',
                $r->pub->name, $r->get_column('pub_score')
            );
    my @voters = $schema->resultset('Votes')->search(
        {
            election => $e->id,
            pub => $r->pub->id
        }
    );
    for my $v (@voters) {
        push(@body,
            sprintf(' * %s (%d points)',
                $v->person->name, (5 - $v->rank) * 2
            )
        );
    }
}

push @body, '';
push @body, sprintf(
    'For more info, see http://eventbot.dryft.net/election/%d/result',
    $e->id
);

my $event_email = Email::Simple->create(
    header => [
        From => $bot->from_addr,
        To   => $bot->list_addr,
        Subject => 'Pub for ' . $thursday->dmy,
    ],
    body => $event_body,
);

my $email = Email::Simple->create(
    header => [
        From => $bot->from_addr,
        To   => $bot->list_addr,
        Subject => 'Election results for ' . $thursday->dmy,
    ],
    body => join("\n", @body),
);


if ($sendmail) {
    send_email($event_email);
    send_email($email);
}
else {
    say " ** TEST MODE ** Not really sending mail to anyone!";
    say $email->as_string;
    say $event_email->as_string;
}


sub send_email {
    my $email = shift;
    sendmail(
        $email,
        {
            from => $bot->config->{imap}{email},
            transport => Email::Sender::Transport::SMTP->new({
                host => 'smtp.gmail.com',
                port => 465,
                sasl_username => $bot->config->{imap}{email},
                sasl_password => $bot->config->{imap}{passwd},
                ssl => $bot->config->{imap}{use_ssl}
            })
        }
    );
}

sub next_thursday {
    my $date = DateTime->now();
    while ($date->day_of_week != 4) {
        $date->add(days => 1);
    }
    return $date;
}
