//
//  HelpCommand.swift
//  Commandant
//
//  Created by Justin Spahr-Summers on 2014-10-10.
//  Copyright (c) 2014 Carthage. All rights reserved.
//

import Foundation
import Result

/// A basic implementation of a `help` command, using information available in a
/// `CommandRegistry`.
///
/// If you want to use this command, initialize it with the registry, then add
/// it to that same registry:
///
/// 	let commands: CommandRegistry<MyErrorType> = …
/// 	let helpCommand = HelpCommand(registry: commands)
/// 	commands.register(helpCommand)
public struct HelpCommand<ClientError: ClientErrorType>: CommandType {
	public typealias Options = HelpOptions<ClientError>

	public let verb = "help"
	public let function = "Display general or command-specific help"

	private let registry: CommandRegistry<ClientError>

	/// Initializes the command to provide help from the given registry of
	/// commands.
	public init(registry: CommandRegistry<ClientError>) {
		self.registry = registry
	}

	public func run(options: Options) -> Result<(), ClientError> {
		if let verb = options.verb {
			if let command = self.registry[verb] {
				print(command.function)
				if let usageError = command.usage() {
					print("\n\(usageError)")
				}
				return .Success(())
			} else {
				fputs("Unrecognized command: '\(verb)'\n", stderr)
			}
		}

		print("Available commands:\n")

		let maxVerbLength = self.registry.commands.map { $0.verb.characters.count }.max() ?? 0

		for command in self.registry.commands {
			let padding = repeatElement(Character(" "), count: maxVerbLength - command.verb.characters.count)
			print("   \(command.verb)\(String(padding))   \(command.function)")
		}

		return .Success(())
	}
}

public struct HelpOptions<ClientError: ClientErrorType>: OptionsType {
	private let verb: String?
	
	private init(verb: String?) {
		self.verb = verb
	}

	private static func create(verb: String) -> HelpOptions {
		return self.init(verb: (verb == "" ? nil : verb))
	}

	public static func evaluate(m: CommandMode) -> Result<HelpOptions, CommandantError<ClientError>> {
		return create
			<*> m <| Argument(defaultValue: "", usage: "the command to display help for")
	}
}
