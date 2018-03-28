#!/usr/bin/perl -w

use strict;
use English qw( -no_match_vars );

use lib './t';
use MyTest;
use MyTestSpecific;
use Cwd;
use File::Path qw (make_path);
use File::Copy;

TEST
{
    my $homedir = $gnupg->options->homedir();
    make_path($homedir, { mode => 0700 });
    my $agentconf = IO::File->new( "> " . $homedir . "/gpg-agent.conf" );
    # Classic gpg can't use loopback pinentry programs like fake-pinentry.pl.
    $agentconf->write(
	"allow-loopback-pinentry\n".
	"pinentry-program " . getcwd() . "/test/fake-pinentry.pl\n"
    ) if $gnupg->cmp_version($gnupg->version, '2.1') >= 0;
    $agentconf->close();
    copy('test/gpg.conf', $homedir . '/gpg.conf');
    # In classic gpg, gpgconf cannot kill gpg-agent. But these tests
    # will not start an agent when using classic gpg. For modern gpg,
    # reset the state of any long-lived gpg-agent, ignoring errors:
    if ($gnupg->cmp_version($gnupg->version, '2.1') >= 0) {
	$ENV{'GNUPGHOME'} = $homedir;
	system('gpgconf', '--quiet', '--kill', 'gpg-agent');
	delete $ENV{'GNUPGHOME'};
    }
    reset_handles();

    my $pid = $gnupg->import_keys(command_args => [ 'test/public_keys.pgp', 'test/secret_keys.pgp', 'test/new_secret.pgp' ],
                                  options => [ 'batch'],
                                  handles => $handles);
    waitpid $pid, 0;

    return $CHILD_ERROR == 0;
};
