//
//  EventViewModel.swift
//  LocalEventsExplorer
//
//  Created by Navdeep Rana on 23/09/26.
//

import Foundation

struct EventViewModel: Identifiable, Equatable {
    let id: UUID
    let title: String
    let locationName: String
    let dateText: String
    let imageURL: URL
    let location: Location
    var isBookmarked: Bool
    var distanceText: String?
}
