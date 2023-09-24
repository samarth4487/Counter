//
//  CounterTests.swift
//  CounterTests
//
//  Created by Samarth Paboowal on 22/09/23.
//

import ComposableArchitecture
import XCTest
@testable import Counter

@MainActor
final class CounterTests: XCTestCase {
    func testCounter() async {
        let store = TestStore(initialState: CounterFeature.State()) {
            CounterFeature()
        }
        
        await store.send(.incrementButtonTapped) {
            $0.count = 1
        }
        
        await store.send(.decrementButtonTapped) {
            $0.count = 0
        }
        
        await store.send(.decrementButtonTapped) {
            $0.count = -1
        }
    }
    
    func testTimer() async {
        let clock = TestClock()
        let store = TestStore(initialState: CounterFeature.State()) {
            CounterFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }
        
        await store.send(.toggleTimerButtonTapped) {
            $0.isTimerOn = true
        }
        
        await clock.advance(by: .seconds(1))
        await store.receive(.timerTicked) {
            $0.count = 1
        }
        
        await clock.advance(by: .seconds(1))
        await store.receive(.timerTicked) {
            $0.count = 2
        }
        
        await store.send(.toggleTimerButtonTapped) {
            $0.isTimerOn = false
        }
    }
    
    func testGetFact() async {
        let store = TestStore(initialState: CounterFeature.State()) {
            CounterFeature()
        } withDependencies: {
            $0.numberFact.fetch = { "\($0) is a great number" }
        }
        
        await store.send(.getFactButtonTapped) {
            $0.isFactLoading = true
        }
        
        await store.receive(.faceResponse("0 is a great number")) {
            $0.fact = "0 is a great number"
            $0.isFactLoading = false
        }
    }
}
