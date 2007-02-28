package Egg::Model::DBIC;
#
# Copyright (C) 2007 Bee Flag, Corp, All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: DBIC.pm 258 2007-02-28 13:17:09Z lushe $
#
use strict;
use warnings;
use UNIVERSAL::require;
use base qw/Egg::Model/;

our $VERSION = '0.02';

sub setup {
	my($class, $e, $conf)= shift->SUPER::setup(@_);
	my $project_name= $e->namespace;
	my $names= $conf->{schema_names} || die q{ I want setup 'schema_names'. };
	if ($e->debug && ! defined($ENV{DBIC_TRACE})) {
		$ENV{DBIC_TRACE} = 1;
		$ENV{DBIC_TRACE}.= "=$conf->{trace_file}" if $conf->{trace_file};
	}
	for my $name (ref($names) eq 'ARRAY' ? @$names: $names) {
		my $schema_class= "$project_name\::Model::DBIC::$name";

		$schema_class->require or Egg::Error->throw($@);
		my $conf= $schema_class->config;
		$conf->{dsn}
		  || Egg::Error->throw(qq{ I want setup '$schema_class'-> 'dsn'.  });
		$conf->{user}
		  || Egg::Error->throw(qq{ I want setup '$schema_class'-> 'user'. });
		$conf->{password} ||= "";
		$conf->{options}  ||= {};

		no strict 'refs';  ## no critic;
		no warnings 'redefine';
		*{"$schema_class\::new"}= $class->_mk_schema_closure
		   ($schema_class, @{$conf}{qw{ dsn user password options }});

		my $model_name= lc($name);
		$e->regist_model($model_name, $schema_class, 1);

		my $schema= $schema_class->new || Egg::Error->throw
		     (qq{ Schema of '$schema_class' cannot be acquired. });
		for my $moniker ($schema->sources) {
			my $moniker_class= "$schema_class\::$moniker";
			$e->regist_model(lc("$name\:$moniker"), $moniker_class);
			*{"$moniker_class\::ACCEPT_CONTEXT"}= sub {
				$_[1]->model($model_name)->resultset($moniker);
			  };
		}
	}
	$class;
}
sub _mk_schema_closure {
	my($class, $schema_class, @source)= @_;
	my $schema;
	sub {
		return $schema if ( $schema
		  && $schema->storage->dbh->{Active}
		  && $schema->storage->dbh->ping
		  );
		$schema= $schema_class->connect(@source);
	  };
}

1;

__END__

=head1 NAME

Egg::Model::DBIC - DBIx::Class for Egg.

=head1 SYNOPSIS

  % cd /MYPROJECT_ROOT/bin
  
  % perl myproject_helper.pl M:DBIC MyApp \
  > -d dbi:Pg:dbname=dbname \
  > -s localhost \
  > -i 5432 \
  > -u db_user \
  > -p db_password
  
  ... done.
  
  output path : /MYPROJECT_ROOT/lib/MYPROJECT/Model/DBIC/MyApp*

Configuration.

  MODEL=> [
    [ DBIC => { schema_names => [qw/ MyApp /] } ],
    ],

Example of code.

  # MYPROJECT::Model::DBIC::MyApp is acquired.
  my $schema= $e->model('myapp');
  
  # If AutoCommit is turning off.
  $schema->storage->txn_begin;
  
  # MYPROJECT::Model::DBIC::MyApp::Moniker is acquired.
  
  my $db= $schema->resultset('Moniker');
  or.
  my $db= $e->model('myapp:moniker');
  
  $db->search( ... );
  
  $schema->storage->txn_commit;
  or.
  $schema->storage->rollback;

* Please see the document of L<DBIx::Class> in detail.

=head1 DESCRIPTION

This module is a model class for DBIx::Class for Egg.

Please make Schema by first handling the helper for use.

  % perl myproject_helper.pl M:DBIC MyDB -d dbi:Pg:dbname=dbname -u user -p passwd

Other modules are generated with this as for '/MYPROJECT/lib/Model/DBIC/MyDB'.

Next, the setting of DBIC is added to the configuration.

  MODEL=> [[ DBIC => { schema_names => [qw/ MyDB /] } ]],

* The name of Schema made for schema_names is only specified.

The object of Schema is acquired specifying everything by the small letter.

  my $schema = $e->model('mydb');

The object of each source delimits by ':' and specifies the name of Schema and
the name of the source. * All are small letters.

  my $source = $e->model('mydb:source');

It learns from the document of L<DBIx::Class> and it operates it when the object
is acquired.

=head1 CREATE SOURCE

Be not in DBIx::Class, and when you make the source by hand power
Please succeed to Egg::Model::DBIC::Moniker and make it.

* DBIx::Class has been succeeded to in Egg::Model::DBIC::Moniker.

Please refer in the module generated with the helper for the sample.

=head1 SEE ALSO

L<DBIx::Class>,
L<Egg::Helper::M::DBIC>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

