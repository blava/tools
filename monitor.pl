#!/usr/bin/perl
use strict;
use warnings;
use Proc::Daemon;
use Time::HiRes qw(usleep sleep);
use DateTime::Functions;
#--------------------------------------------------------------------------------------------------------------------------------#

Proc::Daemon::Init;
my $continue = 1;
$SIG{TERM} = sub { $continue = 0 };

#--------------------------------------------------------------------------------------------------------------------------------#
while ($continue)
{
    &clear_site_search();
    sleep 10;
    &clear_curl();
    sleep 10;
    &clear_lynx();
    sleep 10;
    &cpu_high();
    sleep 10;
    &file_size();
    sleep 10;
}

#--------------------------------------------------------------------------------------------------------------------------------#
#                                      Subroutines Called by Monitor
#--------------------------------------------------------------------------------------------------------------------------------#
sub file_size
{
    my $directory = '/run/shm';
    opendir(DIR, $directory) or die $!;

    while (my $file = readdir(DIR))
    {

        if ($file =~ /\.html/)
        {
            my $filename = '/run/shm/' . $file;
            my $filesize = -s $filename;
            #print $filesize . "\t" . $filename . "\n";

            if ($filesize > 1048576)
            {
                unlink $filename;
            }
        }
    }
}
#--------------------------------------------------------------------------------------------------------------------------------#
sub cpu_high
{
    my $res = `uptime | awk -F 'load average: ' '{print \$2}' | awk -F '.' '{print \$1}'`;

    if ($res > 6) { 
	$res = system("killall -u spider"); 
        &debug("killall -u spider");
        sleep 10;

    }

    if ($res > 8)
    {
        $res = system("service apache2 restart"); 
        &debug("service apache2 restart");
 	sleep 10;
    }
}

#--------------------------------------------------------------------------------------------------------------------------------#
sub clear_curl
{
    my $res =
      `ps -eo pid,etime,args | grep curl | perl -ane '(\$h,\$m,\$s)=split /:/,\$F[1]; system("kill -9 \$F[0]") if (\$h > 0);'`;
}

#--------------------------------------------------------------------------------------------------------------------------------#
sub clear_lynx
{
    my $res =
      `ps -eo pid,etime,args | grep lynx | perl -ane '(\$h,\$m,\$s)=split /:/,\$F[1]; system("kill -9 \$F[0]") if (\$h > 0);'`;
}

#--------------------------------------------------------------------------------------------------------------------------------#
sub clear_site_search
{
    my @array; my @ips; my $ip; my $str; my %hash; my $flag = 0;

    open(FILE, "<", "/var/log/apache2/health.log");
    while (<FILE>)
    {

        if ($_ =~ /(site:|dsafe_mode)/)
        {
            $flag++;
            @array = split(/\s+/, $_);
            $hash{$array[1]}++;

            #--------------------------------------------------#
            #print $_;
            #@ips = split(/\./, $array[1]);
            # Google
            #if (($ips[0] == 66 && $ips[1] == 249)) { }
            #else {
            #    $ip = $ips[0] . '.' . $ips[1] . '.' . $ips[2];
            #    $hash{$ip}++;
            #}
            #--------------------------------------------------#
        }
    }
    close(FILE);

    if ($flag > 0)
    {

        foreach my $key (keys(%hash))
        {
            #$str = "iptables -I INPUT -m iprange --src-range $key.0.0-$key.255.255 -j DROP";
            #$str = "iptables -I INPUT -s $key.0/24 -j DROP";
            $str = "iptables -I INPUT -s $key -j DROP";
            my $res = `$str`;
            &debug($str);
            sleep 0.5;
        }

        my $res = `echo > /var/log/apache2/health.log`;
    }

}

#--------------------------------------------------------------------------------------------------------------------------------#
sub debug
{
  my $message = shift;
  open(DEBUG, ">>/root/debug.log");
  print DEBUG now->strftime("%Y-%m-%d %H:%M:%S") . "\t" .  $message . "\n";
  close(DEBUG);
  sleep 1;
}
#--------------------------------------------------------------------------------------------------------------------------------#

