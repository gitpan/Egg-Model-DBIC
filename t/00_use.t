
use Test::More tests => 6;
BEGIN {
  use_ok('Egg::Model::DBIC');
  use_ok('Egg::Model::DBIC::Schema');
  use_ok('Egg::Model::DBIC::Moniker');
  use_ok('Egg::Helper::M::DBIC');
  use_ok('Egg::Plugin::DBIC::Transaction');
  use_ok('Egg::Plugin::DBIC::TxnDo');
  };

