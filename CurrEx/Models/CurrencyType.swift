//
//  CurrencyType.swift
//  CurrEx
//

import Foundation
import Combine
import SwiftUI

// MARK: - Currency Type
enum CurrencyType: String, CaseIterable, Identifiable {
    case usd = "USD"
    case eur = "EUR"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .usd: return "USD"
        case .eur: return "EUR"
        }
    }
}

// Add compatibility with SwiftUI onChange on iOS 14
#if swift(<5.5)
extension View {
    func onChange<V>(of value: V, perform action: @escaping (V) -> Void) -> some View where V: Equatable {
        modifier(ChangeModifier(value: value, action: action))
    }
}

struct ChangeModifier<Value>: ViewModifier where Value: Equatable {
    var value: Value
    var action: (Value) -> Void
    
    @State private var oldValue: Value
    
    init(value: Value, action: @escaping (Value) -> Void) {
        self.value = value
        self.action = action
        self._oldValue = State(initialValue: value)
    }
    
    func body(content: Content) -> some View {
        content
            .onAppear { oldValue = value }
            .onReceive(Just(value)) { newValue in
                if newValue != oldValue {
                    action(newValue)
                    oldValue = newValue
                }
            }
    }
}
#endif
