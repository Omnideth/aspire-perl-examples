use strict;
use warnings;

use DBI;
use OpenTelemetry::SDK;
use OpenTelemetry;

$| = 1; # autoflush stdout so prints appear in Aspire dashboard immediately

my $tracer = OpenTelemetry->tracer_provider->tracer(
    name    => 'perl-worker-service',
    version => '1.0'
);

# Aspire injects ConnectionStrings__<resource> as an environment variable
# when .WithReference(database) is called in the AppHost.
my $conn_string = $ENV{'ConnectionStrings__database'}
    or die "ConnectionStrings__database environment variable is not set\n";

# Parse the Aspire connection string (format: Host=...;Port=...;Username=...;Password=...;Database=...)
my %params;
for my $pair (split /;/, $conn_string) {
    my ($key, $value) = split /=/, $pair, 2;
    $params{$key} = $value if defined $key && defined $value;
}

my $dsn = sprintf("dbi:Pg:dbname=%s;host=%s;port=%s",
    $params{Database} // 'postgres',
    $params{Host}     // 'localhost',
    $params{Port}     // '5432',
);

my $username = $params{Username} // 'postgres';
my $password = $params{Password} // '';

print "Connecting to database: $dsn\n";

my $dbh = DBI->connect($dsn, $username, $password, {
    AutoCommit => 1,
    RaiseError => 1,
    PrintError => 0,
}) or die "Cannot connect to database: $DBI::errstr\n";

print "Worker service started. Inserting every 60 seconds...\n";

my $tick_count = 0;

while (1) {
    $tracer->in_span('worker_insert' => sub {
        my ($span, $context) = @_;

        $tick_count++;

        my $sth = $dbh->prepare(
            "INSERT INTO activity_log (insertdate, username, count) VALUES (NOW(), ?, ?)"
        );
        $sth->execute('perl-worker', $tick_count);
        $sth->finish;

        $span->set_attribute('db.system'    => 'postgresql');
        $span->set_attribute('worker.tick'  => $tick_count);
        $span->add_event(name => 'row_inserted');

        print "Tick $tick_count: inserted row into activity_log\n";
    });

    sleep 60;
}