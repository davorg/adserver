package TestDatabase;

use strict;
use warnings;
use DBI;
use File::Temp qw(tempdir);
use File::Spec;
use Time::HiRes qw(sleep);
use POSIX qw(WNOHANG);
use AdServer::Schema;

my ($pid, $schema, $dir);

sub startup_error {
    my ($message, $log) = @_;
    open my $fh, '<', $log or die "$message ($log: $!)\n";
    die "$message\n", do { local $/; <$fh> };
}

sub import {
    return if $schema;
    $dir = tempdir('adserver-test-XXXXXX', TMPDIR => 1, CLEANUP => 1);
    my $log = "$dir/server.log";
    my $installer = fork();
    die "fork: $!" unless defined $installer;
    if (!$installer) {
        open STDOUT, '>', $log or die $!;
        open STDERR, '>&', \*STDOUT or die $!;
        exec 'mariadb-install-db', '--no-defaults', "--datadir=$dir/data",
            "--tmpdir=$dir", '--auth-root-authentication-method=normal', '--skip-test-db';
        die "Install MariaDB server tools (mariadb-install-db): $!";
    }
    waitpid($installer, 0);
    startup_error('Database initialization failed', $log) if $?;
    $pid = fork();
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        open STDOUT, '>>', $log or die $!;
        open STDERR, '>&', \*STDOUT or die $!;
        exec 'mariadbd', '--no-defaults', "--datadir=$dir/data",
            "--socket=$dir/mysql.sock", "--pid-file=$dir/mysql.pid",
            "--tmpdir=$dir", '--skip-networking', '--innodb-buffer-pool-size=32M';
        die "Install MariaDB server tools (mariadbd): $!";
    }
    my $dsn = "dbi:mysql:host=localhost;database=mysql;mysql_socket=$dir/mysql.sock";
    my $dbh;
    for (1 .. 200) {
        if (waitpid($pid, WNOHANG) != 0) {
            $pid = undef;
            startup_error('Private database exited during startup', $log);
        }
        $dbh = DBI->connect($dsn, 'root', '', { PrintError => 0, RaiseError => 0 });
        last if $dbh;
        sleep 0.05;
    }
    startup_error('Private database did not start', $log) unless $dbh;
    $dbh->{RaiseError} = 1;
    $dbh->do('CREATE DATABASE adserver_test');
    $dbh->do('USE adserver_test');
    # Resolve from the helper directory, independent of the test working directory.
    require File::Basename;
    my $sql_path = File::Spec->catfile(File::Basename::dirname(__FILE__),
        '..', '..', '..', 'db', 'adserver.sql');
    open my $fh, '<', $sql_path or die "$sql_path: $!";
    my $sql = do { local $/; <$fh> };
    $dbh->do($_) for grep /\S/, split /;/, $sql;
    $dbh->disconnect;
    $schema = AdServer::Schema->connect(
        "dbi:mysql:host=localhost;database=adserver_test;mysql_socket=$dir/mysql.sock",
        'root', '', { mysql_enable_utf8 => 1, quote_char => '`' });
    # Replace only connection construction; routes, models and SQL remain real.
    no warnings 'redefine';
    *AdServer::Schema::get_schema = sub { $schema };
}

sub schema { $schema }

END {
    my $status = $?;
    if ($pid) {
        $schema->storage->disconnect if $schema;
        kill 'TERM', $pid;
        my $stopped;
        for (1 .. 100) {
            if (waitpid($pid, WNOHANG) != 0) { $stopped = 1; last }
            sleep 0.05;
        }
        unless ($stopped) {
            kill 'KILL', $pid;
            waitpid($pid, 0);
        }
    }
    $? = $status;
}

1;
