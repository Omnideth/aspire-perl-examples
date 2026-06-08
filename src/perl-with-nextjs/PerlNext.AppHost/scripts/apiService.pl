use strict;
use warnings;

use DBI;
use Mojolicious::Lite -signatures;
use OpenTelemetry;
use OpenTelemetry::SDK;

$| = 1;

my $tracer = OpenTelemetry->tracer_provider->tracer(
    name    => 'perl-next-api',
    version => '1.0',
);

my $conn_string = $ENV{'ConnectionStrings__appdb'}
    or die "ConnectionStrings__appdb environment variable is not set\n";

my %params;
for my $pair (split /;/, $conn_string) {
    my ($key, $value) = split /=/, $pair, 2;
    $params{$key} = $value if defined $key && defined $value;
}

my $dsn = sprintf(
    'dbi:Pg:dbname=%s;host=%s;port=%s',
    $params{Database} // 'appdb',
    $params{Host}     // 'localhost',
    $params{Port}     // '5432',
);

my $dbh = DBI->connect(
    $dsn,
    $params{Username} // 'postgres',
    $params{Password} // '',
    {
        AutoCommit => 1,
        RaiseError => 1,
        PrintError => 0,
    },
) or die "Cannot connect to database: $DBI::errstr\n";

$dbh->do(q{
    CREATE TABLE IF NOT EXISTS demo_messages (
        id SERIAL PRIMARY KEY,
        headline TEXT NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
});

my ($existing_rows) = $dbh->selectrow_array('SELECT COUNT(*) FROM demo_messages');
if (!$existing_rows) {
    my $insert = $dbh->prepare('INSERT INTO demo_messages (headline) VALUES (?)');
    $insert->execute('Perl API bootstrapped this sample.');
    $insert->execute('Next.js reads from the Perl service through Aspire.');
    $insert->execute('Postgres holds the shared state.');
    $insert->finish;
}

get '/health' => sub ($c) {
    $c->render(json => { status => 'ok' });
};

get '/api/summary' => sub ($c) {
    my %payload = (
        count => 0,
        items => [],
    );

    $tracer->in_span('load_next_summary' => sub {
        my ($span, $context) = @_;

        my $rows = $dbh->selectall_arrayref(
            q{
                SELECT headline, created_at
                FROM demo_messages
                ORDER BY created_at DESC
                LIMIT 5
            },
            { Slice => {} },
        );

        my ($count) = $dbh->selectrow_array('SELECT COUNT(*) FROM demo_messages');

        $payload{count} = $count + 0;
        $payload{items} = $rows;
        $payload{source} = 'Perl + Postgres';

        $span->set_attribute('db.system' => 'postgresql');
        $span->set_attribute('sample.count' => $payload{count});
    });

    $c->render(json => \%payload);
};

post '/api/sometimes' => sub ($c) {
    my $headline = $c->param('headline') // '';
    if ($headline eq '') {
        return $c->render(status => 400, json => { error => 'Headline is required' });
    }

    my $sth = $dbh->prepare('INSERT INTO demo_messages (headline) VALUES (?)');
    $sth->execute($headline);
    $sth->finish;

    $c->render(json => { success => 1 });
};

my $listen_url = sprintf('http://*:%s', $ENV{PORT} // 8080);

if (!@ARGV) {
    @ARGV = ('daemon', '-l', $listen_url);
}
elsif ($ARGV[0] eq 'daemon' && !grep { $_ eq '-l' || $_ eq '--listen' } @ARGV) {
    push @ARGV, '-l', $listen_url;
}

app->start;