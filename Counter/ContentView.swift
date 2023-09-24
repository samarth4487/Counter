//
//  ContentView.swift
//  Counter
//
//  Created by Samarth Paboowal on 22/09/23.
//

import SwiftUI
import ComposableArchitecture

struct NumberFactClient {
    var fetch: @Sendable (Int) async throws -> String
}

extension NumberFactClient: DependencyKey {
    static let liveValue = Self { number in
        let (data, _) = try await URLSession.shared.data(from: URL(string: "http://www.numbersapi.com/\(number)")!)
        return String(decoding: data, as: UTF8.self)
    }
}

extension DependencyValues {
    var numberFact: NumberFactClient {
        get {
            self[NumberFactClient.self]
        }
        
        set {
            self[NumberFactClient.self] = newValue
        }
    }
}

struct CounterFeature: Reducer {
    struct State: Equatable {
        var count = 0
        var fact: String?
        var isFactLoading = false
        var isTimerOn = false
    }
    
    enum Action: Equatable {
        case incrementButtonTapped
        case decrementButtonTapped
        case getFactButtonTapped
        case faceResponse(String)
        case toggleTimerButtonTapped
        case timerTicked
    }
    
    private enum CancelID {
        case timer
    }
    
    @Dependency(\.continuousClock) var clock
    @Dependency(\.numberFact) var numberFact
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .incrementButtonTapped:
                state.count += 1
                state.fact = nil
                return .none
                
            case .decrementButtonTapped:
                state.count -= 1
                state.fact = nil
                return .none
                
            case .getFactButtonTapped:
                state.fact = nil
                state.isFactLoading = true
                return .run { [count = state.count] send in
                    let fact = try await numberFact.fetch(count)
                    await send(.faceResponse(fact))
                }
                
            case let .faceResponse(fact):
                state.fact = fact
                state.isFactLoading = false
                return .none
                
            case .toggleTimerButtonTapped:
                state.isTimerOn.toggle()
                if state.isTimerOn {
                    return .run { send in
                        for await _ in clock.timer(interval: .seconds(1)) {
                            await send(.timerTicked)
                        }
                    }
                    .cancellable(id: CancelID.timer)
                } else {
                    return .cancel(id: CancelID.timer)
                }
                
            case .timerTicked:
                state.count += 1
                return .none
            }
        }
    }
}

struct ContentView: View {
    let store: StoreOf<CounterFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            Form {
                Section {
                    Text("\(viewStore.count)")
                    Button("Increment") {
                        viewStore.send(.incrementButtonTapped)
                    }
                    Button("Decrement") {
                        viewStore.send(.decrementButtonTapped)
                    }
                }
                
                Section {
                    Button {
                        viewStore.send(.getFactButtonTapped)
                    } label: {
                        HStack {
                            Text("Get fact")
                            if viewStore.isFactLoading {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    if let fact = viewStore.fact {
                        Text(fact)
                    }
                }
                
                Section {
                    if viewStore.isTimerOn {
                        Button("Stop timer") {
                            viewStore.send(.toggleTimerButtonTapped)
                        }
                    } else {
                        Button("Start timer") {
                            viewStore.send(.toggleTimerButtonTapped)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView(store: Store(initialState: CounterFeature.State()) {
        CounterFeature()
            ._printChanges()
    })
}
