
use Test::More tests => 4;
BEGIN {
  use_ok('Egg::Model::DBIC');
  use_ok('Egg::Model::DBIC::Schema');
  use_ok('Egg::Helper::Model::DBIC');
  use_ok('Egg::Plugin::DBIC::Transaction');
  };

