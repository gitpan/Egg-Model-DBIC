package Egg::Plugin::DBIC::Transaction;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Transaction.pm 103 2007-05-08 00:20:39Z lushe $
#

=head1 NAME

Egg::Plugin::DBIC::Transaction - Plugin that supports transaction of DBIC.

=head1 SYNOPSIS

  use Egg qw/ DBIC::Transaction /;
  
  __PACKAGE__->egg_startup(
    ...
    .....
    MODEL => [ [ DBIC => {} ] ],
    );

  # Object (MODEL) of MySchema is acquired.
  my $model= $e->myschema_schema;
  
  # dbh of MySchema is acquired.
  my $dbh= $e->myschema_dbh;
  
  # An arbitrary table object is acquired.
  my $table= $e->myschema_table('any_table');
  
  # MySchema is commit.
  $e->myschema_commit;
  
  # MySchema is rollback.
  $e->myschema_rollback;
  
  # After all processing is completed, MySchema is commit.
  $e->myschema_commit_ok(1);
  
  # It is a rollback after all processing is completed as for MySchema.
  $e->myschema_rollback_ok(1);

=head1 DESCRIPTION

It is a plugin that adds an automation of the transaction management by
L<Egg::Model::DBIC> and some convenient accessors.

Interrupt concerning the transaction is done by the call from following Egg.

=over 4

=item * _prepare (Beginning of processing)

Begin of all Schema loaded into L<Egg::Model::DBIC> is done.
However, when AutoCommit is effective, nothing is done.

'begin' need not be done on the application side specifying it.

However, there might be a thing that the overhead cannot be disregarded
according to the number of loaded Schema.
As for measures concerning this, the place today is not included.

=item * _finalize_result (End of processing)

Commit or rollback of all Schema loaded into L<Egg::Model::DBIC> is done.
However, when 'AutoCommit' is effective, nothing is done.

* [schema]_commit_ok is only effective to doing commit.
  'rollback' is done whenever it is invalid.

=item * _finalize_error (Exception is generated)

[schema]_rollback_ok is made effective.

=back

* Because this plugin uses the method of the same to L<Egg::Plugin::DBI::Transaction>
  name, it is not possible to use it at the same time.

=cut
use strict;
use warnings;
use Carp qw/croak/;

our $VERSION = '2.00';

=head1 METHODS

=cut
sub _setup {
	my($e)= @_;
	my $dbic= $e->model('DBIC') || die q{ Please build in MODEL DBIC. };
	my $names= $dbic->config->{schema_names};
	my(@list, %auto_commit);

	no strict 'refs';  ## no critic
	no warnings 'redefine';

	for my $name (ref($names) eq 'ARRAY' ? @$names: $names) {
		$name= lc($name) || next;
		my $schema= $e->model($name)
		   || die qq{ $name Model cannot be acquired. };
		$auto_commit{$name}= $schema->storage->dbh->{AutoCommit} || 0;
		push @list, $name;

=head2 [schema_name]_schema

The object of Schema is returned.

schema_name is always a small letter.

It is the same as $e-E<gt>model([SCHEMA_NAME]).

  my $model= $e->myschema_schema;

=cut
		my $s_method= "${name}_schema";
		*{__PACKAGE__."::$s_method"}=
		   sub { $_[0]->{$s_method} ||= $_[0]->model($name) };

=head2 [schema_name]_dbh

The data base handler of Schema is returned.

It is the same as $e-E<gt>model([SCHEMA_NAME])->storage->dbh.

  my $dbh= $e->myschema_dbh;

=cut
		my $d_method= "${name}_dbh";
		*{__PACKAGE__."::$d_method"}=
		   sub { $_[0]->{$d_method} ||= $_[0]->$s_method->storage->dbh };

=head2 [schema_name]_table ( [TABLE_NAME] )

The table object that belongs to Schema is returned.

$e-E<gt>model([SCHEMA_NAME])->resultset([TABLE_NAME]) or
 $e-E<gt>model([SCHEMA_NAME]:[TABLE_NAME]) It is the same.

  my $table= $e->myschema_table('hoge');

=cut
		*{__PACKAGE__."::${name}_table"}= sub {
			my $egg  = shift;
			my $table= lc(shift) || croak q{ I want source name. };
			$egg->{"dbic_${name}:$table"} ||= $egg->model("${name}:$table");
		  };

=head2 [schema_name]_begin

If the transaction of schema_name is begun and $e-E<gt>debug is effective,
it reports to STDERR.

* This method need not be called from the application specifying it.

=cut
		*{__PACKAGE__."::${name}_begin"}= $auto_commit{$name}
		  ? sub { 1 }: sub {
			$_[0]->$s_method->txn_begin;
			$_[0]->debug_out("# + DBIC '$name' Transaction Start.");
			};

=head2 [schema_name]_commit

If schema_name is 'commit' at once and $e-E<gt>debug is effective,
it reports to STDERR.

  $e->myschema_commit;

=cut
		*{__PACKAGE__."::${name}_commit"}= $auto_commit{$name}
		  ? sub { 1 }: sub {
			$_[0]->$s_method->txn_commit;
			$_[0]->debug_out("# + DBIC '$name' Transaction commit.");
			};

=head2 [schema_name]_rollback

If it goes at once in the rollback of schema_name and $e-E<gt>debug is
effective, it reports to STDERR.

  $e->myschema_rollback;

=cut
		*{__PACKAGE__."::${name}_rollback"}= $auto_commit{$name}
		  ? sub { 0 }: sub {
			$_[0]->$s_method->txn_rollback;
			$_[0]->debug_out("# + DBIC '$name' Transaction rollback.");
			};

=head2 [schema_name]_commit_ok ( [BOOL] )

After all processing ends, schema_name is 'commit' if an effective value is set.

An opposite at the same time value is set in [schema_name]_rollback_ok.

  $e->myschema_commit_ok(1);

=cut
		*{__PACKAGE__."::${name}_commit_ok"}= $auto_commit{$name}
		  ? sub { $_[1] || 0 }: sub {
			my $egg= shift;
			return ($egg->{dbic_commit_ok}{$name} || 0) unless @_;
			(
			  $egg->{dbic_commit_ok}{$name},
			  $egg->{dbic_rollback_ok}{$name},
			  )= $_[0] ? (1, 0): (0, 1);

			$egg->{dbic_commit_ok}{$name};
		  };

=head2 [schema_name]_rollback_ok ( [BOOL] );

After all processing ends, the rollback of schema_name is done if an effective
value is set.

An opposite at the same time value is set in [schema_name]_commit_ok.

  $e->myschema_rollback_ok(1);

=cut
		*{__PACKAGE__."::${name}_rollback_ok"}= $auto_commit{$name}
		  ? sub { $_[1] || 0 }: sub {
			my $egg= shift;
			return ($egg->{dbic_rollback_ok}{$name} || 0) unless @_;
			(
			  $egg->{dbic_rollback_ok}{$name},
			  $egg->{dbic_commit_ok}{$name},
			  )=  $_[0] ? (1, 0): (0, 1);

			$egg->{dbic_rollback_ok}{$name};
		  };

	}

=head2 commit ( [SCHEMA_LIST] )

All [SCHEMA_LIST] is 'commit'.

  $e->commit(qw/ MySchema AnySchema /);

=head2 commit_ok ( [SCHEMA_LIST] )

All 'commit_ok' of [SCHEMA_LIST] is made effective.

  $e->commit_ok(qw/ MySchema AnySchema /);

=head2 rollback ( [SCHEMA_LIST] )

[SCHEMA_LIST] is done and all 'rollback' is done.

  $e->rollback(qw/ MySchema AnySchema /);

=head2 rollback_ok ( [SCHEMA_LIST] )

All rollback_ok of [SCHEMA_LIST] is made effective. 

  $e->rollback_ok(qw/ MySchema AnySchema /);

=cut
	for my $accessor (qw/ commit commit_ok rollback rollback_ok /) {

		*{__PACKAGE__."::$accessor"}= sub {
			my $egg= shift;
			&{ lc($_). "_$_" }($egg, 1) for @_;
			1;
		  };

	}

	$e->global->{dbic_transactions}= \@list;
	$e->global->{dbic_auto_commit} = \%auto_commit;
	$e->next::method;
}

{
	no strict 'refs';  ## no critic
	sub _prepare {
		my($e)= @_;
		$e->{dbic_commit_ok}  = {};
		$e->{dbic_rollback_ok}= {};
		&{"$_\_begin"}($e) for @{$e->global->{dbic_transactions}};
		$e->next::method;
	}
	sub _finalize_error {
		my($e)= @_;
		&{"$_\_rollback_ok"}($e, 1) for @{$e->global->{dbic_transactions}};
		$e->next::method;
	}
  };

sub _finalize_result {
	my($e)= @_;
	for my $name (@{$e->global->{dbic_transactions}}) {
		my $method= $e->{dbic_commit_ok}{$name}
		                ? "${name}_commit": "${name}_rollback";
		$e->$method;
	}
	$e->next::method;
}

=head1 SEE ALSO

L<DBIx::Class>,
L<Egg::Model::DBIC>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
