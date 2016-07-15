<?php

function parse_file($filename) {
    $file = fopen($filename, "r");
    $source = fread($file, filesize($filename));

    $tokens = token_get_all($source);

    $cachedVars = array();
    $cachedFunctions = array();
    $cachedFunctionComplex = array();
    $tmpFunc = array();

    $insideFunc = false;
    $isClousure = true;
    $haveParameters = false;
    $snippetCount = 1;

    foreach($tokens as $token) {
        switch($token[0]) {
            case T_FUNCTION:
                $insideFunc = true;
                break;
            case T_STRING:
                if($insideFunc) {
                    $isClousure = false;

                    if ($token[1] !== null) {
                        if (!in_array($token[1], $cachedFunctions)) {
                            $cachedFunctions[] = $token[1];
                            $tmpFunc[] =  $token[1];
                        }
                    } else {
                        $insideFunc = false;
                    }
                }
                break;
            case '(':
                if ($insideFunc && !$isClousure) {
                    $haveParameters = true;
                }
                break;
            case ')':
                if ($insideFunc && $haveParameters) {
                    $cachedFunctionComplex[] = $tmpFunc;
                    $tmpFunc = array();
                    $snippetCount = 1;
                }

                $haveParameters = false;
                $isClousure = true;
                $insideFunc = false;
                break;
            case T_VARIABLE:
                if ($haveParameters) {
                    $tmpFunc[] = '${' . $snippetCount++ . ':' . $token[1] . '}';
                }

                if (!in_array($token[1], $cachedVars)) {
                    $cachedVars[] = $token[1];
                }
                break;
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


    $localFuncs = array();

    foreach ($cachedFunctionComplex as $funObj) {
        if (isset($funObj[0])) {
            $tmp = [
                'text' => $funObj[0],
                'type' => 'function',
                'snippet' => array_shift($funObj) . '(' . implode(', ', $funObj) . ')${99}',
            ];

            array_push($localFuncs, $tmp);
        }
    }

    return ['user_vars' => $localVars, 'user_functions' => $localFuncs];
}

$editing_file = fread(STDIN, 1024);
$dirname = dirname($editing_file);

$r = ['user_vars' => array(), 'user_functions' => array()];

$files = scandir($dirname);
foreach ($files as $filename) {
    $ext = pathinfo($filename, PATHINFO_EXTENSION);
    if (strtolower($ext) == 'php') {
        $r0 = parse_file($dirname.'/'.$filename);
        $r['user_vars'] = array_merge($r['user_vars'], $r0['user_vars']);
        $r['user_functions'] = array_merge($r['user_functions'], $r0['user_functions']);
    }
}

echo json_encode($r);
