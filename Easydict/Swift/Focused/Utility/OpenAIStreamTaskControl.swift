// Extracted unchanged from BaseOpenAIService.swift. Copyright © 2026 izual. GPL-3.0.

import Foundation

final class OpenAIStreamTaskControl: @unchecked Sendable {
    // MARK: Internal

    func begin(identifier: UUID) {
        lock.lock()
        let previousTask = activeRequest?.task
        activeRequest = ActiveRequest(identifier: identifier, task: nil)
        lock.unlock()
        previousTask?.cancel()
    }

    func install(_ task: Task<(), Never>, identifier: UUID) {
        lock.lock()
        guard activeRequest?.identifier == identifier else {
            lock.unlock()
            task.cancel()
            return
        }
        activeRequest?.task = task
        lock.unlock()
    }

    func finish(identifier: UUID) {
        lock.lock()
        if activeRequest?.identifier == identifier {
            activeRequest = nil
        }
        lock.unlock()
    }

    func cancel() {
        lock.lock()
        let task = activeRequest?.task
        activeRequest = nil
        lock.unlock()
        task?.cancel()
    }

    func cancel(identifier: UUID) {
        lock.lock()
        guard activeRequest?.identifier == identifier else {
            lock.unlock()
            return
        }
        let task = activeRequest?.task
        activeRequest = nil
        lock.unlock()
        task?.cancel()
    }

    // MARK: Private

    private struct ActiveRequest {
        let identifier: UUID
        var task: Task<(), Never>?
    }

    private let lock = NSLock()
    private var activeRequest: ActiveRequest?
}
