package EventBot::Schema::Endorsements;
use strict;
use warnings;
use parent 'DBIx::Class';

__PACKAGE__->load_components(qw(Core));
__PACKAGE__->table('endorsements');
__PACKAGE__->add_columns(
    person => { data_type => 'INTEGER', is_nullable => 0 },
    pub => { data_type => 'INTEGER', is_nullable => 0 },
);
__PACKAGE__->set_primary_key(qw(person pub));
__PACKAGE__->has_many(person => 'EventBot::Schema::People');
__PACKAGE__->has_many(pub => 'EventBot::Schema::Pubs');

1;
