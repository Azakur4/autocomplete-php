<?php
    parse_str(implode('&', array_slice($argv, 1)), $_GET);

    $file = $_GET['filePath'];
    $source = file_get_contents($file);
    $tokens = token_get_all($source);

    $functions = array();
    $nextStringIsFunc = false;
    $inClass = false;
    $bracesCount = 0;

    foreach($tokens as $token) {
        switch($token[0]) {
            case T_FUNCTION:
                $nextStringIsFunc = true;
                break;
            case T_STRING:
                if($nextStringIsFunc) {
                    $nextStringIsFunc = false;
                    $functions[] = $token[1];
                }
                break;
        }
    }


    $ar = [];

    foreach ($functions as $fun) {
        $tmp = [
            "text" => $fun,
            "type" => "function",
        ];

        array_push($ar, $tmp);
    }

    echo json_encode(["user_functions" => $ar]);
