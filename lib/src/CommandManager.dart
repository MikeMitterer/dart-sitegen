part of sitegen;

class CommandManager {
    static String SASS = "sass";
    static String SASSC = "sassc";
    static String AUTOPREFIXER = "autoprefixer-cli";
    static String SAY = "say";
    // static String OSASCRIPT = "osascript";

    static CommandManager _commandmanager;

    final Map<String,Command> _commands;

    static Future<CommandManager> getInstance() async {
        if(_commandmanager == null) {
            final commands = await _getAvailableCommands();
            _commandmanager = new CommandManager._private(commands);
        }
        return _commandmanager;
    }

    Command operator [](final String key) => _commands[key];

    bool containsKey(final String key) => _commands.containsKey(key);

    // - private -----------------------------------------------------------------------------------

    CommandManager._private(this._commands);
}

class Command {
    final String name;
    final String exe;
    //final CommandWrapper wrapper;

    Command(this.name, this.exe);

}

/// Test if necessary commands are available
Future<Map<String,Command>> _getAvailableCommands() async {
    final Map<String,Command> commands = new Map<String,Command>();
    final List<String> names
        = <String>[

            CommandManager.SASS,
            CommandManager.SASSC,
            CommandManager.AUTOPREFIXER,
            CommandManager.SAY,
            //CommandManager.OSASCRIPT,
        ];

    await Future.forEach(names, (final String binName) async {
        try {
            final String exe = await where(binName);
            commands[binName] = new Command(binName,exe);
        } catch(_) {  }

    });

    return commands;
}