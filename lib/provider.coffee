module.exports =
  # This will work on JavaScript and CoffeeScript files, but not in js comments.
  selector: '.source.php'
  # disableForSelector: '.source.php .comment'

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
    console.log request
    new Promise (resolve) =>
      resolve(@getKeywordNameCompletions(request))

  # (optional): called _after_ the suggestion `replacementPrefix` is replaced
  # by the suggestion `text` in the buffer
  onDidInsertSuggestion: ({editor, triggerPosition, suggestion}) ->

  # (optional): called when your provider needs to be cleaned up. Unsubscribe
  # from things, kill any processes, etc.
  dispose: ->

  getKeywordNameCompletions: ({prefix}) ->
    completions = []
    lowerCasePrefix = prefix.toLowerCase()
    console.log lowerCasePrefix

    for keyword in @completions.keywords when keyword.text.indexOf(lowerCasePrefix) is 0
      completions.push(@buildCompletion(keyword))

    # for constants in @completions.constants when constants.text.indexOf(lowerCasePrefix) is 0
    #   completions.push(@buildCompletion(constants))

    for variable in @completions.variables when variable.text.indexOf(lowerCasePrefix) is 0
      console.log variable
      completions.push(@buildCompletion(variable))

    completions

  buildCompletion: (keyword) ->
    text: keyword.text
    type: keyword.type
    # snipet: keyword.snippet?
    # description: "PHP <#{keyword.text}> keyword"
    # descriptionMoreURL: "@getTagDocsURL(tag)"
