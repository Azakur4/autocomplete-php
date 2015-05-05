<?php
    parse_str(implode('&', array_slice($argv, 1)), $_GET);

    $file = $_GET['filePath'];
    $source = file_get_contents($file);
    $tokens = token_get_all($source);

    $cachedVars = array();

    foreach($tokens as $token) {
        if ($token[0] === T_VARIABLE) {
            if (!in_array($token[1], $cachedVars)) {
                $cachedVars[] = $token[1];
            }
        }
    }

    $localVars = array();

    foreach ($cachedVars as $var) {
        $tmp = [
            "text" => substr($var, 1),
            "type" => "variable",
        ];

        array_push($localVars, $tmp);
    }

    echo json_encode(["user_vars" => $localVars]);
