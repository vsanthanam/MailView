// MailView
// MailView.swift
//
// MIT License
//
// Copyright (c) 2021 Varun Santhanam
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the  Software), to deal
//
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED  AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import MessageUI
import SwiftUI
import UIKit

/// A wrapper around `MFMailComposeViewController` for use in SwiftUI
///
/// ## Topics
///
/// ### Initializers
///
/// - ``init(subject:toRecipients:messageBody:onDismiss:)``
///
/// ### Modifiers
///
/// - ``subject(_:)``
/// - ``toRecipents(_:)``
/// - ``messageBody(_:)``
/// - ``plainMessageBody(_:)``
/// - ``richMessageBody(_:)``
/// - ``onDismiss(_:)``
public struct MailView: UIViewControllerRepresentable {

    // MARK: - Initializers

    public init(subject: String? = nil,
                toRecipients: [String]? = nil,
                messageBody: MessageBody = .empty,
                onDismiss: ((Result<MFMailComposeResult, Error>) -> Void)? = nil) {
        self.subject = subject
        self.toRecipients = toRecipients
        self.messageBody = messageBody
        self.onDismiss = onDismiss
    }

    // MARK: - API

    public static var canSendMail: Bool {
        MFMailComposeViewController.canSendMail()
    }

    public enum MessageBody: ExpressibleByStringLiteral {
        case plain(String)
        case html(String)
        case empty

        public typealias StringLiteralType = String

        public init(stringLiteral value: StringLiteralType) {
            self = .plain(value)
        }
    }

    public func subject(_ subject: String?) -> MailView {
        var copy = self
        copy.subject = subject
        return copy
    }

    public func toRecipents(_ toRecipients: [String]?) -> MailView {
        var copy = self
        copy.toRecipients = toRecipients
        return copy
    }

    public func messageBody(_ messageBody: MessageBody) -> MailView {
        var copy = self
        copy.messageBody = messageBody
        return copy
    }

    public func plainMessageBody(_ body: String?) -> MailView {
        var copy = self
        if let body = body {
            copy.messageBody = .plain(body)
        } else {
            copy.messageBody = .empty
        }
        return copy
    }

    public func richMessageBody(_ body: String?) -> MailView {
        var copy = self
        if let body = body {
            copy.messageBody = .html(body)
        } else {
            copy.messageBody = .empty
        }
        return copy
    }

    public func onDismiss(_ action: ((Result<MFMailComposeResult, Error>) -> Void)?) -> MailView {
        var copy = self
        copy.onDismiss = action
        return copy
    }

    // MARK: - UIViewControllerRepresentable

    public final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {

        // MARK: - MFMailComposeViewControllerDelegate

        public func mailComposeController(_ controller: MFMailComposeViewController,
                                          didFinishWith result: MFMailComposeResult,
                                          error: Error?) {
            defer {
                dismiss()
            }
            if let error = error {
                onDismiss?(.failure(error))
            } else {
                onDismiss?(.success(result))
            }
        }

        // MARK: - Private

        fileprivate init(dismiss: DismissAction,
                         subject: String? = nil,
                         toRecipients: [String]?,
                         messageBody: MessageBody = .empty,
                         onDismiss: ((Result<MFMailComposeResult, Error>) -> Void)?) {
            self.dismiss = dismiss
            self.subject = subject
            self.toRecipients = toRecipients
            self.messageBody = messageBody
            self.onDismiss = onDismiss
        }

        private let dismiss: DismissAction
        private let subject: String?
        private let toRecipients: [String]?
        private let messageBody: MessageBody
        private let onDismiss: ((Result<MFMailComposeResult, Error>) -> Void)?
    }

    public func makeCoordinator() -> Coordinator {
        .init(dismiss: dismiss,
              subject: subject,
              toRecipients: toRecipients,
              messageBody: messageBody,
              onDismiss: onDismiss)
    }

    public func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        if let subject = subject {
            vc.setSubject(subject)
        }
        vc.setToRecipients(toRecipients)
        switch messageBody {
        case let .plain(string):
            vc.setMessageBody(string, isHTML: false)
        case let .html(string):
            vc.setMessageBody(string, isHTML: true)
        case .empty:
            break
        }
        vc.mailComposeDelegate = context.coordinator
        return vc
    }

    public func updateUIViewController(_ uiViewController: MFMailComposeViewController,
                                       context: UIViewControllerRepresentableContext<MailView>) {}

    // MARK: - Private

    @Environment(\.dismiss)
    private var dismiss: DismissAction

    private var subject: String?
    private var toRecipients: [String]?
    private var messageBody: MessageBody
    private var onDismiss: ((Result<MFMailComposeResult, Error>) -> Void)?
}

public extension View {

    /// Present a `MailView`
    /// - Parameters:
    ///   - isPresented: A binding which determines whether or not the view is presented
    ///   - mailView: A closure used to build the presented view
    /// - Returns: The modified view
    func mailView(isPresented: Binding<Bool>,
                  mailView: @escaping () -> MailView) -> some View {
        sheet(isPresented: isPresented,
              content: { mailView() })
    }

    /// Present a `MailView`
    /// - Parameters:
    ///   - item: Binding which determines whether or not the view is presented
    ///   - mailView: A closure used to build the presented view
    /// - Returns: The modified view
    func mailView<T>(item: Binding<T?>,
                     mailView: @escaping (T) -> MailView) -> some View where T: Identifiable {
        sheet(item: item,
              content: { item in mailView(item) })
    }
}
