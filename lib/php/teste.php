<?php

    $source = '';

    while ($a = fread(STDIN, 1024)) {
        $source .= $a;
    }

    // $f = fgets(STDIN);

    echo $source;

?>
