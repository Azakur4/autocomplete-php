<?php
    $functions = get_defined_functions()["internal"];
    sort($functions);
    $ar = [];

    foreach ($functions as $fun) {
        $tmp = [
            "text" => $fun,
            "type" => "function",
            "descriptionMoreURL" => "http://php.net/manual/en/function." . str_replace('_', '-', $fun) . ".php"
        ];

        array_push($ar, $tmp);
    }

    $myFile = fopen("functions.json", "w");
    fwrite($myFile, json_encode(["functions" => $ar], JSON_PRETTY_PRINT));
    fclose($myFile);
