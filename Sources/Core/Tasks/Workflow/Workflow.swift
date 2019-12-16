//
//  Workflow.swift
//  Colorizer
//
//  Created by khoa on 01/12/2019.
//

import Foundation
import Combine

/// Workflow is a group of tasks
public class Workflow {
    public let name: String
    public var workingDirectory: String = "."
    public let tasks: [Task]

    private let beforeSummarizer = BeforeSummarizer()
    private let afterSummarizer = AfterSummerizer()

    public init(name: String, tasks: [Task]) {
        self.name = name
        self.tasks = tasks
    }

    public init(name: String, @TaskBuilder builder: () -> [Task]) {
        self.name = name
        self.tasks = builder()
    }

    public init(name: String, @TaskBuilder builder: () -> Task) {
        self.name = name
        self.tasks = [builder()]
    }

    public func run(completion: @escaping TaskCompletion = { _ in }) {
        beforeSummarizer.on(tasks: tasks)
        Sequence(tasks: tasks).run(workflow: self, completion: { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                self.handle(error: error)
                completion(.failure(error))
            }
        })
    }

    public func handle(error: Error) {
        guard let pumaError = error as? PumaError else {
            Deps.console.error(error.localizedDescription)
            return
        }

        switch pumaError {
        case .process(let terminationStatus, let output, let error):
            let _ = output
            Deps.console.error("code \(terminationStatus)")
            Deps.console.error(error)
        default:
            Deps.console.error(error.localizedDescription)
        }
    }
}
