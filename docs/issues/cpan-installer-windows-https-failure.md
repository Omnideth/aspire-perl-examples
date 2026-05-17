# Windows CPAN installer fails under Aspire, but normal shell and a trivial wrapper succeed

## Summary

On Windows with Strawberry Perl, the default `cpan` installer path used by
`CommunityToolkit.Aspire.Hosting.Perl` fails inside the Aspire-created installer
resource during an HTTPS fetch from `cpan.org`.

The same machine succeeds in all of these cases:

- direct shell `cpan -f -T -i JSON::PP`
- direct shell `HTTP::Tiny->new()->get("https://cpan.org/")`
- a normal Aspire-launched Perl app resource making the same HTTPS request
- an Aspire installer resource that resolves `cpan` to a trivial wrapper batch
  file which only prints env and then `call`s the real Strawberry `cpan.bat`

That makes this look much less like a missing CA bundle and much more like a
Windows batch-launch / `cpan.bat` invocation problem in the installer-resource
path.

## Environment

- OS: Windows
- Aspire CLI: `13.4.0-preview.1.26264.12`
- `CommunityToolkit.Aspire.Hosting.Perl`: `13.3.0`
- Strawberry Perl: `5.42.0`
- `HTTP::Tiny`: `0.090`
- `IO::Socket::SSL`: `2.095`
- `Net::SSLeay`: `1.94`
- sample: `src/perl-hello`

## Minimal repro

Use the default `cpan` path in `src/perl-hello/apphost.cs`:

```csharp
#:package CommunityToolkit.Aspire.Hosting.Perl@13.3.0
#:sdk Aspire.AppHost.Sdk@13.4.0-preview.1.26264.12

using Aspire.Hosting;

var builder = DistributedApplication.CreateBuilder(args);

var hello = builder.AddPerlScript("hello", "scripts", "hello.pl");

hello.WithPackage("JSON::PP", force: true, skipTest: true);

builder.Build().Run();
```

To avoid a false pass from cached CPAN artifacts, remove the cached tarball and
checksums first:

```powershell
Remove-Item 'C:\Strawberry\cpan\sources\authors\id\I\IS\ISHIGAKI\JSON-PP-4.18.tar.gz' -ErrorAction SilentlyContinue
Remove-Item 'C:\Strawberry\cpan\sources\authors\id\I\IS\ISHIGAKI\CHECKSUMS' -ErrorAction SilentlyContinue
```

Then start the sample and inspect the installer logs:

```powershell
Set-Location "src\perl-hello"
aspire start
aspire logs JSON88PP-installer
```

## Actual result

The installer fails on the HTTPS fetch from `cpan.org`:

```text
CPAN: IO::Socket::SSL loaded ok (v2.095)
Fetching with HTTP::Tiny:
https://cpan.org/authors/id/I/IS/ISHIGAKI/JSON-PP-4.18.tar.gz
HTTP::Tiny failed with an internal error: SSL connection failed for cpan.org: SSL connect attempt failed error:0A000086:SSL routines::certificate verify failed
```

## Expected result

The installer should behave the same way as direct shell `cpan` on the same
machine and complete the package install successfully.

## Evidence that this is not a general Windows CA problem

### 1. Direct shell behavior is healthy

- `cpan -f -T -i JSON::PP` succeeds outside Aspire
- `HTTP::Tiny->new()->get("https://cpan.org/")` succeeds outside Aspire
- `IO::Socket::SSL::default_ca()` resolves to Strawberry Perl's Mozilla CA
  bundle:

```text
C:\Strawberry\perl\vendor\lib\Mozilla\CA\cacert.pem
```

### 2. A normal Aspire-launched Perl app can do HTTPS successfully

I temporarily instrumented `src/perl-hello/scripts/hello.pl` and ran it as a
normal Aspire app resource. Under Aspire, that process had a working CA setup
and a successful HTTPS request:

- `SSL_CERT_FILE=C:\Strawberry\perl\vendor\lib\Mozilla\CA\cacert.pem`
- `SSL_CERT_DIR=<Aspire temp resource cert dir>`
- `IO::Socket::SSL::default_ca()` resolved correctly
- `HTTP::Tiny GET https://cpan.org/` returned `200`

So the failure is not "all Aspire-launched Perl executables on Windows fail
HTTPS". It is narrower than that.

### 3. The installer resource itself receives the expected visible trust env

I forced the installer to resolve `cpan` to a temporary wrapper earlier on
`PATH`, and that wrapper dumped the installer env before delegating to the real
`C:\Strawberry\perl\bin\cpan.bat`.

The captured installer env included:

```text
APPDATA=C:\Users\<user>\AppData\Roaming
LOCALAPPDATA=C:\Users\<user>\AppData\Local
USERPROFILE=C:\Users\<user>
SSL_CERT_FILE=C:\Strawberry\perl\vendor\lib\Mozilla\CA\cacert.pem
SSL_CERT_DIR=C:\Users\<user>\AppData\Local\Temp\aspire-...\certs
```

So the obvious "missing SSL_CERT_FILE / missing user profile" explanation does
not fit the observed installer environment.

## Strongest signal: a trivial wrapper fixes it

This wrapper was enough to change the behavior:

```bat
@echo off
setlocal
echo [cpan-wrapper] BEGIN ENV
set APPDATA
set LOCALAPPDATA
set USERPROFILE
set HOME
set SSL_CERT_FILE
set SSL_CERT_DIR
set HTTPS_CA_FILE
set PERL_LWP_SSL_CA_FILE
echo [cpan-wrapper] END ENV
call "C:\Strawberry\perl\bin\cpan.bat" %*
exit /b %ERRORLEVEL%
```

With that wrapper at the front of `PATH`, and after clearing the cache again,
the Aspire installer successfully performed a fresh HTTPS fetch:

```text
Fetching with HTTP::Tiny:
https://cpan.org/authors/id/I/IS/ISHIGAKI/JSON-PP-4.18.tar.gz
Fetching with HTTP::Tiny:
https://cpan.org/authors/id/I/IS/ISHIGAKI/CHECKSUMS
Checksum for C:\STRAWB~1\cpan\sources\authors\id\I\IS\ISHIGAKI\JSON-PP-4.18.tar.gz ok
```

The wrapper does not add a CA bundle. It just changes how the real
`cpan.bat` gets invoked.

That strongly suggests the bug is in one of these places:

- Windows batch-file launch semantics for Aspire/DCP executable resources
- command resolution / installer launch behavior in
  `CommunityToolkit.Aspire.Hosting.Perl`
- a Strawberry `cpan.bat` quirk that only shows up when launched the way the
  installer resource launches it directly

## Related observation about `WithPerlCertificateTrust()`

The installed package docs say:

- `WithPerlCertificateTrust(...)` sets `SSL_CERT_FILE`,
  `PERL_LWP_SSL_CA_FILE`, and `MOJO_CA_FILE`
- `TryAttachCertificateTrustToInstallerResource(...)` "Applies SSL/TLS
  certificate trust environment variables to a single installer resource."
- `TryAttachCertificateTrustToExistingInstallers(...)` "Propagates certificate
  trust to all existing installer child resources."

Even so, enabling `WithPerlCertificateTrust()` did not fix this direct `cpan`
failure in my testing.

That lines up with the wrapper result: the break appears to be in invocation
shape, not in the absence of visible trust env.

## Why `cpanm` success is not proof that `cpan` is healthy

`WithCpanMinus()` is a workable sample-level fallback on Windows, but it does
not prove the `cpan` HTTPS path is correct. In the observed successful run,
`cpanm` fetched from `http://www.cpan.org/...`, so it never exercised the same
HTTPS + `HTTP::Tiny` path that `cpan` uses here.

## Likely next checks

1. Inspect how the installer resource launches `.bat` / `.cmd` on Windows.
2. Compare direct `cpan.bat` launch with `cmd.exe /d /c call cpan.bat ...`.
3. Check whether Strawberry's `cpan.bat` is sensitive to `%0`, quoting, or
   shell context when invoked the way the installer does.
4. If the generic executable-resource path is already correct, inspect the Perl
   integration's installer-command resolution for Windows batch files.

## Bottom line

This does not look like a general "Perl on Windows cannot validate HTTPS under
Aspire" bug.

It looks specifically like: Aspire's installer-resource path can launch
Strawberry Perl's `cpan.bat` in a way that breaks the CPAN shell's HTTPS fetch,
while the same machine, same CA bundle, same Perl install, and even the same
installer env all work when `cpan.bat` is reached through a trivial wrapper.