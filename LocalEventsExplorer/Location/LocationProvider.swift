//
//  LocationProvider.swift
//  LocalEventsExplorer
//
//  Created by Navdeep Rana on 23/09/26.
//

import Combine
import Foundation

struct Location: Equatable {
    let latitude: Double
    let longitude: Double
}

protocol LocationProvider {
    /// Emits the latest known user location, or `nil` while unknown / denied.
    var locationPublisher: AnyPublisher<Location?, Never> { get }

    func requestLocation()
}
