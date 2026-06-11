use strict;
use warnings;

use Mojolicious::Lite -signatures;
use OpenTelemetry;
use OpenTelemetry::SDK;

$| = 1;

my $tracer = OpenTelemetry->tracer_provider->tracer(
    name    => 'perl-angular-api',
    version => '1.0',
);

get '/health' => sub ($c) {
    $c->render(json => { status => 'ok' });
};

get '/api/info' => sub ($c) {
    my %payload = (
        framework => 'Angular',
        message   => 'The camel can be your backend.',
        source    => 'Mojolicious',
    );

    $tracer->in_span('load_angular_info' => sub {
        my ($span, $context) = @_;

        $payload{timestamp} = scalar(gmtime);
        $payload{port} = $ENV{PORT} // '8080';

        $span->set_attribute('frontend.framework' => 'angular');
        $span->set_attribute('sample.port' => $payload{port});
    });

    $c->render(json => \%payload);
};

my $listen_url = sprintf('http://*:%s', $ENV{PORT} // 8080);

if (!@ARGV) {
    @ARGV = ('daemon', '-l', $listen_url);
}
elsif ($ARGV[0] eq 'daemon' && !grep { $_ eq '-l' || $_ eq '--listen' } @ARGV) {
    push @ARGV, '-l', $listen_url;
}

app->start;