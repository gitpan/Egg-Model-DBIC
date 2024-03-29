use Module::Build;

my $builder = Module::Build->new(

  module_name       => 'Egg::Model::DBIC',
  dist_version_from => 'lib/Egg/Model/DBIC.pm',
  dist_author       => 'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>',
  license           => 'perl',

  requires => {

    'Egg::Release' => 2.00,
    'DBIx-Class'   => 0.07999,
    'DBIx::Class::Schema::Loader' => 0.03,

    'Test::Simple'          => 0,
    'Test::Pod'             => 0,
    'Test::Perl::Critic'    => 0,
    'Test::Pod::Coverage'   => 0,
    },

  );

$builder->create_build_script();
