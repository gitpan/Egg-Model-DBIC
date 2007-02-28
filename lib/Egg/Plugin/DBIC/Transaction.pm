package Egg::Plugin::DBIC::Transaction;
#
# Copyright (C) 2007 Bee Flag, Corp, All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: DBIC.pm 254 2007-02-26 15:08:15Z lushe $
#
use strict;
use warnings;

our $VERSION = '0.01';

sub setup {
	my($e)= @_;
	my $dbic = $e->model('DBIC') || die q{ Please build in MODEL DBIC. };
	my $names= $dbic->config->{schema_names};
	my(@list, %auto_commit);
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	for my $name (ref($names) eq 'ARRAY' ? @$names: $names) {
		$name= lc($name) || next;
		my $schema= $e->model($name)
		   || Egg::Error->throw(qq{ $name Model cannot be acquired. });
		$auto_commit{$name}= 1 if $schema->storage->dbh->{AutoCommit};
		push @list, $name;

	## schema Method.
		my $smethod= "$name\_schema";
		*{__PACKAGE__."::$smethod"}=
		   sub { $_[0]->{$smethod} ||= $_[0]->model($name) };

	## dbh Method.
		my $dmethod= "$name\_dbh";
		*{__PACKAGE__."::$dmethod"}=
		   sub { $_[0]->{$dmethod} ||= $_[0]->$smethod->storage->txn_dbh };

	## table Method.
		*{__PACKAGE__."::$name\_table"}= sub {
			my $egg= shift;
			my $table= lc(shift)
			   || Egg::Error->throw(q{ I want source name. });
			$egg->model("$name\:$table");
		  };

	## begin Method.
		*{__PACKAGE__."::$name\_begin"}= $auto_commit{$name}
		  ? sub { 1 }: sub {
			$_[0]->$smethod->txn_begin;
			$_[0]->debug_out("# + DBIC Transaction Start.");
			};

	## commit Method.
		*{__PACKAGE__."::$name\_commit"}= $auto_commit{$name}
		  ? sub { 1 }: sub {
			$_[0]->$smethod->txn_commit;
			$_[0]->debug_out("# + DBIC Transaction commit.");
			};

	## rollback Method.
		*{__PACKAGE__."::$name\_rollback"}= $auto_commit{$name}
		  ? sub { 0 }: sub {
			$_[0]->$smethod->txn_rollback;
			$_[0]->debug_out("# + DBIC Transaction rollback.");
			};

	## commit_ok Method.
		*{__PACKAGE__."::$name\_commit_ok"}= $auto_commit{$name}
		  ? sub { $_[1] || 0 }: sub {
			my $egg= shift;
			return ($egg->{dbic_commit_ok}{$name} || 0) unless @_;
			(
			  $egg->{dbic_commit_ok}{$name},
			  $egg->{dbic_rollback_ok}{$name},
			  )= $_[0] ? (1, 0): (0, 1);

			$egg->{dbic_commit_ok}{$name};
		  };

	## rollback_ok Method.
		*{__PACKAGE__."::$name\_rollback_ok"}= $auto_commit{$name}
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

	for my $a ([qw{ commit 1 }],
	  [qw{ commit_ok 1 }], [qw{ rollback 1 }], [qw{ rollback_ok 1 }]) {
		*{__PACKAGE__."::$a->[0]"}= sub {
			my $egg= shift;
			@_ || Egg::Error->throw('I want schema names.');
			for (@_) { my $method= lc($_). "_$a->[0]"; $egg->$method(1) }
			return $a->[1];
		  };
	}
	$e->config->{__dbic_transactions}= \@list;
	$e->config->{__dbic_auto_commit} = \%auto_commit;
	$e->next::method;
}
sub prepare {
	my($e)= @_;
	$e->{dbic_commit_ok}  = {};
	$e->{dbic_rollback_ok}= {};
	for my $name (@{$e->config->{__dbic_transactions}})
	  { my $method= "$name\_begin"; $e->$method }
	$e->next::method;
}
sub output_content {
	my($e)= @_;
	for my $name (@{$e->config->{__dbic_transactions}}) {
		my $method= $e->{dbic_commit_ok}{$name}
		   ? "$name\_commit": "$name\_rollback";
		$e->$method;
	}
	$e->{finished_transaction}= 1;
	$e->next::method;
}
sub error_finalize {
	my($e)= @_;
	return $e->next::method if $e->{finished_transaction};
	for my $name (@{$e->config->{__dbic_transactions}})
	  { my $method= "$name\_rollback"; $e->$method }
	$e->next::method;
}

1;

__END__

=head1 NAME

Egg::Plugin::DBIC::Transaction - The method related to the transaction etc. of DBIC for Egg is offered.

=head1 SYNOPSIS

  my $dbh= $e->myapp_dbh;                    # <= $e->model('myApp')->storage->txn_dbh;
  
  my $schema= $e->myapp_schema;              # <= $e->model('myApp');
  
  my $table = $e->myapp_table('myMoniker');  # <= $e->model('myApp:myMoniker');
  
  $e->myapp_commit;                          # <= $e->model('myApp')->storage->txn_commit;
  
  # Two or more Schema is settled and commit is done.
  $e->commit(qw/ myApp remoteApp /);
  
  # When the processing of Egg ends, commit is done.
  $e->myapp_commit_ok(1);
  
  # Commit_ok of two or more Schema is settled and set.
  $e->commit_ok(qw/ myApp remoteApp /);
  
  $e->myapp_rollback;                        # <= $e->model('myApp')->storage->txn_rollback;
  
  # Two or more Schema is settled and rollback is done.
  $e->rollback(qw/ myApp remoteApp /);
  
  # When the processing of Egg ends, rollback is done.
  $e->myapp_rollback_ok(1);
  
  # Rollback_ok of two or more Schema is settled and set.
  $e->rollback_ok(qw/ myApp remoteApp /);

=head1 DESCRIPTION

This plug-in offers a convenient accessor to treat DBIC, and semi-automates
the processing of the transaction.

BEGIN is always done at the start of processing of Egg and the transaction is 
begun. And, when processing is ended, COMMIT is done and the transaction is
ended if ROLLBACK or commit_ok is effective.

As a result, it comes do not to have to consider BEGIN and ROLLBACK, etc. on
the application side.

* Please make commit_ok effective in the application when you do COMMIT.

L<DBIx::Class> : L<http://search.cpan.org/dist/DBIx-Class/lib/DBIx/Class/Manual/DocMap.pod>.

=head1 METHODS

* The error doesn't occur even when AutoCommit is invalidly used.
  Moreover, the method doesn't do anything even if called.
  However, the method for the data base handler and the model acquisition
  functions.

=head2 [schema_name]_begin.

The transaction of Schema is begun.

Because this is called by the automatic operation when processing begins, it is
not necessary to call from the application.

=head2 [schema_name]_dbh

The data base handler of Schema is returned.

* It is the same as $e->model([schema_name])->storage->txn_dbh.

=head2 [schema_name]_schema

The object of Schema is returned.

* It is the same as $e->model([schema_name]).

=head2 [schema_name]_table ([source_name])

The table object in Schema is returned.

* It is the same as $e->model([schema_name])->resultset([source_name])
  and $e->model([schema_name]:[source_name]).

=head2 [schema_name]_commit

COMMIT of Schema is issued.

* It is the same as $e->model([schema_name])->storage->txn_commit.

=head2 [schema_name]_rollback

ROLLBACK of Schema is issued.

* It is the same as $e->model([schema_name])->storage->txn_rollback.

=head2 [schema_name]_commit_ok([Boolean]);

It is reserved to do COMMIT when the transaction is ended.

* 0 If is passed, it becomes a cancellation.

=head2 [schema_name]_rollback_ok([Boolean]);

Because it tries to issue ROLLBACK whenever the transaction is ended, this 
method need not usually be called. * To make the syntax comprehensible.

=head2 commit ([schema_list])

COMMIT does all passed Schema.

=head2 commit_ok ([schema_list])

COMMIT of all passed Schema is reserved.

=head2 rollback ([schema_list])

ROLLBACK does all passed Schema.

=head2 rollback_ok ([schema_list])

ROLLBACK of all passed Schema is reserved.


=head1 SEE ALSO

L<Egg::Model::DBIC>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
