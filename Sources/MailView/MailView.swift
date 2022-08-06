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

public struct MailView: UIViewControllerRepresentable {

    // MARK: - Initializers

    public init(subject: String? = nil,
                toRecipients: [String]? = [],
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

    private let subject: String?
    private let toRecipients: [String]?
    private let messageBody: MessageBody
    private let onDismiss: ((Result<MFMailComposeResult, Error>) -> Void)?
}
