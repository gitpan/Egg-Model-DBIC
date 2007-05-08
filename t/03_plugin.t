
use Test::More qw/no_plan/;
use Egg::Helper::VirtualTest;
use DBI;

my $dsn   = $ENV{EGG_RDBMS_DSN}        || "";
my $uid   = $ENV{EGG_RDBMS_USER}       || "";
my $psw   = $ENV{EGG_RDBMS_PASSWORD}   || "";
my $table = $ENV{EGG_RDBMS_TEST_TABLE} || 'egg_release_dbi_test_table';

SKIP: {
skip q{ Data base is not setup. } unless ($dsn and $uid);

my $t= Egg::Helper::VirtualTest->new;
my $g= $t->global;

@{$g}{qw/ dbic_dsn dbic_uid dbic_psw dbic_table /}= ($dsn, $uid, $psw, $table);

$t->prepare(
  controller   => { egg_includes => [qw/ DBIC::Transaction /] },
  config       => { MODEL=> [ [ DBIC => {} ] ] },
  create_files => [ $t->yaml_load( join '', <DATA> ) ],
  );

my $dbh= DBI->connect($dsn, $uid, $psw, { AutoCommit => 1, RaiseError=> 1 });

eval{
	$dbh->do(<<"END_ST");
CREATE TABLE $table (
  id     int2      primary key,
  test   varchar
  );
END_ST
  };

my $pname= $t->project_name;
ok my $e = $t->egg_pcomp_context;
can_ok 'Egg::Plugin::DBIC::Transaction', qw/
   _prepare
   _finalize_error
   _finalize_result
   /;
can_ok $e, qw/
   schema_schema
   schema_dbh
   schema_table
   schema_begin
   schema_commit
   schema_rollback
   schema_commit_ok
   schema_rollback_ok
   commit rollback
   commit_ok
   rollback_ok
   /;

ok my $schema= $e->schema_schema;
isa_ok $schema, "${pname}::DBIC::Schema";
isa_ok $schema, "Egg::Model::DBIC::Schema";
isa_ok $schema, "DBIx::Class::Schema";

ok my $d= $e->schema_dbh;
isa_ok $d, "DBI::db";

ok my $moniker= $e->schema_table('moniker');
is $moniker, 0;
isa_ok $moniker, 'DBIx::Class';
isa_ok $moniker, 'DBIx::Class::ResultSet';

ok $e->commit('schema');
ok $e->commit_ok('schema');
ok $e->rollback('schema');
ok $e->rollback_ok('schema');

$dbh->do("DROP TABLE $table");
$dbh->disconnect;

  };

__DATA__
---
filename: lib/<$e.project_name>/DBIC/Schema.pm
value: |
  package <$e.project_name>::DBIC::Schema;
  use strict;
  use warnings;
  use base qw/Egg::Model::DBIC::Schema/;
  our $VERSION = '0.01';
  
  __PACKAGE__->config(
    dsn      => '<$e.dbic_dsn>',
    user     => '<$e.dbic_uid>',
    password => '<$e.dbic_psw>',
    options  => { AutoCommit => 1, RaiseError=> 1 },
    );
  
  __PACKAGE__->load_classes;
  
  1;
---
filename: lib/<$e.project_name>/DBIC/Schema/Moniker.pm
value: |
  package <$e.project_name>::DBIC::Schema::Moniker;
  use strict;
  use warnings;
  use base qw/DBIx::Class/;
  our $VERSION = '0.01';
  
  __PACKAGE__->load_components("PK::Auto", "Core");
  __PACKAGE__->table("<$e.dbic_table>");
  __PACKAGE__->add_columns(
    "id", {
      data_type   => "smallint",
      is_nullable => 0,
      },
    "test", {
      data_type     => "character varying",
      default_value => undef,
      is_nullable   => 0,
      },
   );
  
  1;
