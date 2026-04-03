use strict;
use warnings;

use DBI;
use OpenTelemetry::SDK;
use OpenTelemetry;
use Mojolicious::Lite -signatures;

$| = 1;

my $tracer = OpenTelemetry->tracer_provider->tracer(
    name    => 'perl-api-service',
    version => '1.0'
);

# Aspire injects ConnectionStrings__<resource> when .WithReference(database) is used.
my $conn_string = $ENV{'ConnectionStrings__postgres'}
    or die "ConnectionStrings__postgres environment variable is not set\n";

my %params;
for my $pair (split /;/, $conn_string) {
    my ($key, $value) = split /=/, $pair, 2;
    $params{$key} = $value if defined $key && defined $value;
}

my $dsn = sprintf(
    "dbi:Pg:dbname=%s;host=%s;port=%s",
    $params{Database} // 'postgres',
    $params{Host}     // 'localhost',
    $params{Port}     // '5432',
);

my $username = $params{Username} // 'postgres';
my $password = $params{Password} // '';

print "API connecting to database: $dsn\n";

my $dbh = DBI->connect(
    $dsn,
    $username,
    $password,
    {
        AutoCommit => 1,
        RaiseError => 1,
        PrintError => 0,
    }
) or die "Cannot connect to database: $DBI::errstr\n";

get '/health' => sub ($c) {
    $c->render(json => { status => 'ok' });
};

get '/api/activity' => sub ($c) {
    my $limit = $c->param('limit') // 50;
    $limit = 1   if $limit < 1;
    $limit = 200 if $limit > 200;

    my $rows;
    my $error;

    $tracer->in_span('api_read_activity' => sub {
        my ($span, $context) = @_;

        eval {
            my $sth = $dbh->prepare(
                q{
                    SELECT insertdate, username, "count" AS tick_count
                    FROM activity_log
                    ORDER BY insertdate DESC
                    LIMIT ?
                }
            );
            $sth->execute($limit);
            $rows = $sth->fetchall_arrayref({});
            $sth->finish;

            $span->set_attribute('db.system' => 'postgresql');
            $span->set_attribute('api.limit' => $limit + 0);
            $span->set_attribute('api.rows'  => scalar(@$rows));
        };

        if ($@) {
            $error = "$@";
            $span->set_attribute('error' => 1);
            $span->add_event(name => 'query_failed', attributes => { message => $error });
        }
    });

    if ($error) {
        $c->render(
            status => 500,
            json   => {
                error => 'Failed to query activity_log',
                detail => $error,
            }
        );
        return;
    }

    $c->render(
        json => {
            count => scalar(@$rows),
            items => $rows,
        }
    );
};

if (!@ARGV) {
    my $port = $ENV{PORT} // 8080;
    @ARGV = ('daemon', '-l', "http://*:$port");
}

app->start;
