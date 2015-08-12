{CompositeDisposable} = require 'atom'
provider = require './provider'

module.exports =
  config:
    executablePath:
      type: 'string'
      title: 'PHP Executable Path'
      default: 'php' # Let OS's $PATH handle the rest

  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe 'autocomplete-php.executablePath',
      (executablePath) ->
        provider.executablePath = executablePath
    provider.loadCompletions()

  deactivate: ->
    @subscriptions.dispose()

  getProvider: -> provider
