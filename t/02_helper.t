
use Test::More qw/no_plan/;
use Egg::Helper::VirtualTest;
use DBI;

my $dsn   = $ENV{EGG_RDBMS_DSN}        || "";
my $uid   = $ENV{EGG_RDBMS_USER}       || "";
my $psw   = $ENV{EGG_RDBMS_PASSWORD}   || "";
my $table = $ENV{EGG_RDBMS_TEST_TABLE} || 'egg_release_dbi_test_table';

SKIP: {
skip q{ Data base is not setup. } unless ($dsn and $uid);

my $t= Egg::Helper::VirtualTest->new( prepare => {} );
my $g= $t->global;

my $dbh= DBI->connect($dsn, $uid, $psw, { AutoCommit => 1, RaiseError=> 1 });
eval{

	$dbh->do(<<"END_ST");
CREATE TABLE $table (
  id     int2      primary key,
  test   varchar
  );
END_ST

	$dbh->do(<<END_ST);
CREATE TABLE egg_plugin_session_table (
  id        char(32)   primary key,
  lastmod   timestamp,
  a_session text
  );
END_ST

  };

ok $t->helper_run('Model:DBIC', 'TestSchema');
ok -e "$g->{schema_path}.pm";
ok -e "$g->{schema_path}";

$dbh->do("DROP TABLE $table");
$dbh->disconnect;

 };
