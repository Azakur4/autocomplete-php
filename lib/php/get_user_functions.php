<?php
    $source = '';

    while ($a = fread(STDIN, 1024)) {
        $source .= $a;
    }

    $tokens = token_get_all($source);

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
                break;
        }
    }


    $localFuncs = array();

    foreach ($cachedFunctionComplex as $funObj) {
        $tmp = [
            'text' => $funObj[0],
            'type' => 'function',
            'snippet' => array_shift($funObj) . '(' . implode(', ', $funObj) . ')${99}',
        ];

        array_push($localFuncs, $tmp);
    }

    echo json_encode(['user_functions' => $localFuncs]);
