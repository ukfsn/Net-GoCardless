# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-GoCardless.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('Net::GoCardless') };

ok(my $go = Net::GoCardless->new({
    'client_id' => '123',
    'access_token' => 'asdjkasdlkj1234123'
    }), "new accepts input");


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

