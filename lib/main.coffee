provider = require './provider'

module.exports =
  activate: ->
    provider.loadCompletions()

    atom.commands.add 'atom-workspace', 'autocomplete-php:startServer', -> provider.startServer()
    atom.commands.add 'atom-workspace', 'autocomplete-php:stopServer', -> provider.stopServer()
    atom.commands.add 'atom-workspace', 'autocomplete-php:indexProject', -> provider.indexer()

  getProvider: -> provider
