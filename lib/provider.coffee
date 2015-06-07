exec = require 'child_process'
fs = require 'fs'
path = require 'path'
req = require 'request'

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

  indexer: () ->
    projectPath = atom.project.getPaths()[0]
    generatorCmd = __dirname + '/padawan/bin/indexer.php'

    proc = exec.spawn generatorCmd, ['generate'], {cwd: projectPath}

    proc.stdout.on 'data', (data) ->
      console.log 'stdout: ' + data

    proc.stderr.on 'data', (data) ->
      console.log 'stderr: ' + data

    proc.on 'close', (code) ->
      console.log 'End with code: ' + code

  startServer: ->
    serverCmd = __dirname + '/padawan/bin/server.php'

    @padaServ = exec.spawn 'php', [serverCmd]

    @padaServ.stdout.on 'data', (data) ->
      console.log 'stdout: ' + data

    @padaServ.stderr.on 'data', (data) ->
      console.log 'stderr: ' + data

    @padaServ.on 'close', (code) ->
      console.log 'End with code: ' + code

    @padaServIsRunning = true
    @loadCompletions = []

  stopServer: ->
    if !@padaServIsRunning
      return false

    @padaServ.kill()
    @padaServIsRunning = false

  execute: ({editor}) ->
    urlParams = {
      filepath: editor.getPath()
      line: editor.getCursorBufferPosition().row + 1
      column: editor.getCursorBufferPosition().column + 1
      path: atom.project.getPaths()[0] + '/'
    }

    urlParams.filepath = urlParams.filepath.replace(urlParams.path + '/', '')

    contents = editor.getText()

    headersParams = {
      'Content-Length': contents.length
    }

    req.post {headers: headersParams, url: 'http://localhost:15155/complete?filepath=' + urlParams.filepath + '&line=' + urlParams.line + '&column=' + urlParams.column + '&path=' + urlParams.path, form: contents}, (error, response, body) =>
      # console.log error
      # console.log response
      padawanCompletions = JSON.parse(body)

      if padawanCompletions.completion?.length > 0
        @loadCompletions = padawanCompletions

  # Required: Return a promise, an array of suggestions, or null.
  # {editor, bufferPosition, scopeDescriptor, prefix}
  getSuggestions: (request) ->
    new Promise (resolve) =>
      if @padaServIsRunning?
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

  getCompletions: ({editor, prefix}) ->
    completions = []
    lowerCasePrefix = prefix.toLowerCase()

    for sugges in @loadCompletions?.completion when sugges.name.toLowerCase().indexOf(lowerCasePrefix) is 0
      completions.push(@buildCompletion({ text: sugges.name, type: 'function', leftLabel: sugges.signature, description: sugges.description}))

    return completions

  buildCompletion: (suggestion) ->
    text: suggestion.text
    type: suggestion.type
    displayText: suggestion.displayText ?= null
    snippet: suggestion.snippet ?= null
    leftLabel: suggestion.leftLabel ?= null
    description: suggestion.description ?= "PHP <#{suggestion.text}> #{suggestion.type}"
    descriptionMoreURL: suggestion.descriptionMoreURL ?= null
