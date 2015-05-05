exec = require "child_process"

module.exports =
  # This will work on JavaScript and CoffeeScript files, but not in js comments.
  selector: '.source.php'
  disableForSelector: '.source.php .comment'
  # keyword.operator.class.php

  # This will take priority over the default provider, which has a priority of 0.
  # `excludeLowerPriority` will suppress any providers with a lower priority
  # i.e. The default provider will be suppressed
  inclusionPriority: 1
  excludeLowerPriority: true

  # Load Completions from json
  loadCompletions: ->
    @completions = {}
    fs.readFile path.resolve(__dirname, '..', 'completions.json'), (error, content) =>
      @completions = JSON.parse(content) unless error?
      return

    @funtions = {}
    fs.readFile path.resolve(__dirname, '..', 'functions.json'), (error, content) =>
      @funtions = JSON.parse(content) unless error?
      return

  execute: ({editor}) ->
    stdout = exec.execSync 'php ' + __dirname + '/php/get_user_functions.php filePath=' + editor.getPath()
    @userFunctions = JSON.parse(stdout)

  # Required: Return a promise, an array of suggestions, or null.
  # {editor, bufferPosition, scopeDescriptor, prefix}
  getSuggestions: (request) ->
    new Promise (resolve) =>
      if @notShowAutocomplete(request)
        resolve([])
      else if @isVariable(request)
        resolve(@getVarsCompletions(request))
      else if @isFunCon(request)
        @execute(request)
        resolve(@getCompletions(request))
      else
        resolve([])

  # (optional): called _after_ the suggestion `replacementPrefix` is replaced
  # by the suggestion `text` in the buffer
  onDidInsertSuggestion: ({editor, triggerPosition, suggestion}) ->

  # (optional): called when your provider needs to be cleaned up. Unsubscribe
  # from things, kill any processes, etc.
  dispose: ->

  notShowAutocomplete: ({scopeDescriptor}) ->
    scopes = scopeDescriptor.getScopesArray()
    return true if scopes.indexOf('keyword.operator.assignment.php') isnt -1 or
      scopes.indexOf('keyword.operator.comparison.php') isnt -1 or
      scopes.indexOf('keyword.operator.logical.php') isnt -1 or
      scopes.indexOf('string.quoted.double.php') isnt -1 or
      scopes.indexOf('string.quoted.single.php') isnt -1 or
      scopes.length < 4

  isVariable: ({scopeDescriptor}) ->
    scopes = scopeDescriptor.getScopesArray()
    return true if scopes.indexOf('variable.other.php') isnt -1

  isFunCon: ({scopeDescriptor}) ->
    scopes = scopeDescriptor.getScopesArray()
    return true if scopes.indexOf('constant.other.php') isnt -1 or
      scopes.indexOf('keyword.control.php') isnt -1 or
      scopes.indexOf('storage.type.php') isnt -1 or
      scopes.indexOf('support.function.construct.php')

  getCompletions: ({editor, prefix}) ->
    completions = []
    lowerCasePrefix = prefix.toLowerCase()

    for constants in @completions.constants when constants.text.toLowerCase().indexOf(lowerCasePrefix) is 0
      completions.push(@buildCompletion(constants))

    for keyword in @completions.keywords when keyword.text.toLowerCase().indexOf(lowerCasePrefix) is 0
      completions.push(@buildCompletion(keyword))

    for func in @funtions.functions when func.text.toLowerCase().indexOf(lowerCasePrefix) is 0
      completions.push(@buildCompletion(func))

    for userFunc in @userFunctions.user_functions when userFunc.text.toLowerCase().indexOf(lowerCasePrefix) is 0
      completions.push(@buildCompletion(userFunc))

    completions

  getVarsCompletions: ({editor, prefix}) ->
    completions = []
    lowerCasePrefix = prefix.toLowerCase()

    tokenVar = /[$][\a-zA-Z_][a-zA-Z0-9_]*/g;
    varList = editor.getText().match(tokenVar);
    @cachedLocalVariables = [];

    if varList
      for _var in varList
        if @cachedLocalVariables.indexOf(_var) == -1 and _var.substr(1) != prefix
          @cachedLocalVariables.push {text: _var.substr(1), type: 'variable'}

    for localVar in @cachedLocalVariables when localVar.text.toLowerCase().indexOf(lowerCasePrefix) is 0
      completions.push(@buildCompletion(localVar))

    for variable in @completions.variables when variable.text.toLowerCase().indexOf(lowerCasePrefix) is 0
      completions.push(@buildCompletion(variable))

    completions


  buildCompletion: (suggestion) ->
    text: suggestion.text
    type: suggestion.type
    displayText: suggestion.displayText ?= null
    snippet: suggestion.snippet ?= null
    leftLabel: suggestion.leftLabel ?= null
    description: suggestion.description ?= "PHP <#{suggestion.text}> #{suggestion.type}"
    descriptionMoreURL: suggestion.descriptionMoreURL ?= null
