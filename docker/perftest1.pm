package perftest1;

use nginx;

sub handler {
    my $r = shift;
    my $webroot = "/app/web/mnt";

    $r->send_http_header("text/html");
    return OK if $r->header_only;
    chdir "$webroot";

    $r->print("<html><title>Disk IO Performance test</title><body>\n<br>");

    my $PODNAME = $ENV{HOSTNAME};

    my $f = "$webroot/perftest.$PODNAME.txt";
    if (! -f "$f") { ### note: only triggers on first run
        $r->print("<h2>Perftest not started!</h2>\n");
        $r->print("<a href=\"../start/\">Go to start</a>\n");
        $r->print("</body></html>");
        return OK;
    }
    if (-f "$webroot/perftest.$PODNAME.run" ) {
        $r->print("<h2>Perftest is currently running!</h2>\n");
        $r->print("<h3>Reload this page until it finishes.</h3><br>");
    } else {
        $r->print("<h2>Perftest is finished!</h2>\n<br>");
    }

    $r->print("Output from $f<br>\n<h2><pre>");
    if ( -f "$f" ) {
        local $/;
        open(F,"<$f") or die "Can't read file $f [$!]\n";  
        $lines = <F>;
        close(F);
        $r->print($lines);
    }

    $r->print("</pre>");
    $r->print("</body></html>");

    return OK;
}

1;
