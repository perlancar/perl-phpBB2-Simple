package phpBB2::Simple;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any '$log';

use DBI;

our %SPEC;

our %common_args = (
    db_dsn => {
        schema => 'str*',
        req => 1,
        tags => ['common'],
    },
    db_user => {
        schema => 'str*',
        req => 1,
        tags => ['common'],
    },
    db_password => {
        schema => 'str*',
        req => 1,
        tags => ['common'],
    },
);

our %detail_arg = (
    detail => {
        summary => 'Returned detailed record for each item instead of just ID',
        schema => 'bool',
    },
);

sub __env {
    state $env;
    if (@_) {
        $env = $_[0];
    }
    $env;
}

sub __conf {
    __env()->{'app.config'};
}

sub __dbh {
    state $dbh;
    if (!$dbh) {
        my %args = @_;
        $dbh = DBI->connect(
            $args{db_dsn}, $args{db_user}, $args{db_password},
            {RaiseError=>1},
        );
    }
    $dbh;
}

$SPEC{list_users} = {
    v => 1.1,
    args => {
        %common_args,
        %detail_arg,
        active => {
            summary => 'Only list active users',
            schema  => 'bool',
            tags    => ['category:filtering'],
        },
        level => {
            summary => 'Only list users having certain level',
            schema  => ['str*', in=>['user', 'moderator', 'administrator']],
            tags    => ['category:filtering'],
        },
    },
};
sub list_users {
    my %args = @_;

    my $detail = $args{detail};

    my $sth = __dbh->prepare("SELECT * FROM phpbb_users ORDER BY username");
    $sth->execute;
    my @rows;
    while (my $row = $sth->fetchrow_hashref) {

        next if defined($args{active}) &&
            $args{active} xor $row->{user_active};

        if (defined $args{level}) {
            next if $args{level} eq 'user' && $row->{user_level} != 0;
            next if $args{level} eq 'administrator' && $row->{user_level} != 1;
            next if $args{level} eq 'moderator' && $row->{user_level} != 2;
        }

        if ($args{detail}) {
            push @rows, {
                username  => $row->{username},
                email     => $row->{user_email},
                is_active => $row->{user_active},
                level     =>
                    $row->{user_level} == 0 ? "user" :
                        $row->{user_level} == 1 ? "administrator" :
                            $row->{user_level} == 2 ? "moderator" : "?",
            };
        } else {
            push @rows, $row->{username};
        }
    }
    [200, "OK", \@rows];
}

1;
# ABSTRACT:

=head1 SYNOPSIS


=head1 DESCRIPTION

I know, phpBB2 is beyond ancient (2007 and earlier), but our intranet board
still runs it and some things are more convenient to do via CLI script than via
web-based administration panel.


=head1 FUNCTIONS

None of the functions are currently exported.

=cut
