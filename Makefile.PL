use inc::Module::Install;

name         'Egg-Model-DBIC';
all_from     'lib/Egg/Model/DBIC.pm';
version_from 'lib/Egg/Model/DBIC.pm';
author       'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>';
license      'perl';

requires 'Egg::Release' => 2.00;
requires 'DBIx-Class'   => 0.07999;
requires 'DBIx::Class::Schema::Loader' => 0.03;

build_requires 'Test::Simple';
build_requires 'Test::Pod';
build_requires 'Test::Perl::Critic';
build_requires 'Test::Pod::Coverage';

use_test_base;
auto_include;
WriteAll;
