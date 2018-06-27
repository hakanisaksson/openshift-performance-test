package perftest2;

use nginx;

sub handler {
    my $r = shift;
    my $webroot = "/app/web/mnt";

    $r->send_http_header("text/html");
    return OK if $r->header_only;
    chdir "$webroot";

    my $PODNAME = $ENV{HOSTNAME};

    $r->print("<html><title>Disk IO Performance test</title><body>\n<br>");

    if (-f "$webroot/perftest.$PODNAME.run" ) {
        $r->print("<h2>Perftest is currently running!</h2>\n");
        $r->print("<a href=\"../view/\">Go to resluts page</a>");
    } else {
        $r->print("<h2>Starting Perftest!</h2>\n<br>");
        $r->print("<a href=\"../view/\">Go to results page</a>");
        system("/perftest.sh &");
    }

    $r->print("</pre>");
    $r->print("</body></html>");

    return OK;
}

1;
