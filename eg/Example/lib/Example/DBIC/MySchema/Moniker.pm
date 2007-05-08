package Example::DBIC::MySchema::Moniker;
use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("PK::Auto", "Core");
__PACKAGE__->table("moniker");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "smallint",
    default_value => undef,
    is_nullable => 0,
    size => 2,
  },
  "test",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("id");

1;
