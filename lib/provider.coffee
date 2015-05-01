module.exports =
  # This will work on JavaScript and CoffeeScript files, but not in js comments.
  selector: '.source.php'
  disableForSelector: '.source.php .comment'

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

  # Required: Return a promise, an array of suggestions, or null.
  # {editor, bufferPosition, scopeDescriptor, prefix}
  getSuggestions: (request) ->
    new Promise (resolve) =>
      resolve(@getCompletions(request))

  # (optional): called _after_ the suggestion `replacementPrefix` is replaced
  # by the suggestion `text` in the buffer
  onDidInsertSuggestion: ({editor, triggerPosition, suggestion}) ->

  # (optional): called when your provider needs to be cleaned up. Unsubscribe
  # from things, kill any processes, etc.
  dispose: ->

  getCompletions: ({prefix}) ->
    completions = []
    lowerCasePrefix = prefix.toLowerCase()

    for func in @completions.functions when func.text.toLowerCase().indexOf(lowerCasePrefix) is 0
      completions.push(@buildCompletion(func))

    for keyword in @completions.keywords when keyword.text.toLowerCase().indexOf(lowerCasePrefix) is 0
      completions.push(@buildCompletion(keyword))

    # for constants in @completions.constants when constants.text.toLowerCase().indexOf(lowerCasePrefix) is 0
    #   completions.push(@buildCompletion(constants))

    for variable in @completions.variables when variable.text.toLowerCase().indexOf(lowerCasePrefix) is 0
      completions.push(@buildCompletion(variable))

    # \$([a-zA-Z_\x7f-\xff][a-zA-Z0-9_\x7f-\xff]*)
    tokenVar = /[$][\a-zA-Z_][a-zA-Z0-9_]*/g;
    editor = atom.workspace.getActiveTextEditor()
    varList = editor.getText().match(tokenVar);
    @cachedLocalVariables = [];

    if varList
      for _var in varList
        if @cachedLocalVariables.indexOf(_var) == -1
          @cachedLocalVariables.push {text: _var.substr(1), type: 'variable'}

    for localVar in @cachedLocalVariables when localVar.text.toLowerCase().indexOf(lowerCasePrefix) is 0
      completions.push(@buildCompletion(localVar))

    completions

  buildCompletion: (suggestion) ->
    text: suggestion.text
    type: suggestion.type
    leftLabel: suggestion.leftLabel ?= ''
    # snipet: keyword.snippet?
    description: suggestion.description ?= "PHP <#{suggestion.text}> #{suggestion.type}"
    descriptionMoreURL: suggestion.descriptionMoreURL ?= ''
