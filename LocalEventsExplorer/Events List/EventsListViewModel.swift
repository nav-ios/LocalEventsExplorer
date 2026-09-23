//
//  EventsListViewModel.swift
//  LocalEventsExplorer
//
//  Created by Navdeep Rana on 23/09/26.
//

import Combine
import CoreLocation
import EventsFeed
import Foundation

@MainActor
final class EventsListViewModel: ObservableObject {
    typealias EventsPublisher = () -> AnyPublisher<[Event], Error>

    @Published private(set) var events = [EventViewModel]()
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published var showsBookmarkedOnly = false

    static let loadErrorMessage = "Couldn't load events. Showing what we have."

    private let eventsPublisher: EventsPublisher
    private let bookmarks: BookmarksRepository
    private let locationProvider: LocationProvider
    private let dateFormatter: DateFormatter
    private let distanceFormatter: MeasurementFormatter

    private var userLocation: Location?
    private var cancellable: Cancellable?
    private var bookmarkCancellables = Set<AnyCancellable>()
    private var locationCancellable: AnyCancellable?

    init(eventsPublisher: @escaping EventsPublisher, bookmarks: BookmarksRepository, locationProvider: LocationProvider, locale: Locale = .current, timeZone: TimeZone = .current) {
        self.eventsPublisher = eventsPublisher
        self.bookmarks = bookmarks
        self.locationProvider = locationProvider
        self.dateFormatter = EventsListViewModel.makeDateFormatter(locale: locale, timeZone: timeZone)
        self.distanceFormatter = EventsListViewModel.makeDistanceFormatter(locale: locale)
    }

    var visibleEvents: [EventViewModel] {
        return showsBookmarkedOnly ? events.filter(\.isBookmarked) : events
    }

    func load() {
        isLoading = true
        errorMessage = nil

        cancellable = eventsPublisher()
            .zip(bookmarks.loadBookmarkedEventIDs().replaceError(with: []).setFailureType(to: Error.self))
            .dispatchOnMainQueue()
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure = completion {
                    self?.errorMessage = EventsListViewModel.loadErrorMessage
                }
            }, receiveValue: { [weak self] events, bookmarkedIDs in
                self?.display(events, bookmarkedIDs: bookmarkedIDs)
            })
    }

    func startUpdatingLocation() {
        locationCancellable = locationProvider.locationPublisher
            .dispatchOnMainQueue()
            .sink { [weak self] location in
                self?.userLocation = location
                self?.refreshDistances()
            }
        locationProvider.requestLocation()
    }

    func toggleBookmark(for id: UUID) {
        guard let index = events.firstIndex(where: { $0.id == id }) else { return }

        let willBookmark = !events[index].isBookmarked
        events[index].isBookmarked = willBookmark

        let update = willBookmark ? bookmarks.addBookmark(for: id) : bookmarks.removeBookmark(for: id)
        update
            .dispatchOnMainQueue()
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure = completion, let index = self?.events.firstIndex(where: { $0.id == id }) {
                    self?.events[index].isBookmarked = !willBookmark
                }
            }, receiveValue: { })
            .store(in: &bookmarkCancellables)
    }

    // MARK: - Private

    private func display(_ events: [Event], bookmarkedIDs: Set<UUID>) {
        self.events = events.map { event in
            EventViewModel(
                id: event.id,
                title: event.title,
                locationName: event.location.name,
                dateText: dateFormatter.string(from: event.time),
                imageURL: event.imageURL,
                location: Location(latitude: event.location.latitude, longitude: event.location.longitude),
                isBookmarked: bookmarkedIDs.contains(event.id),
                distanceText: distanceText(to: Location(latitude: event.location.latitude, longitude: event.location.longitude))
            )
        }
    }

    private func refreshDistances() {
        events = events.map { event in
            var event = event
            event.distanceText = distanceText(to: event.location)
            return event
        }
    }

    private func distanceText(to location: Location) -> String? {
        guard let userLocation = userLocation else { return nil }

        let from = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let to = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let metres = Measurement(value: to.distance(from: from), unit: UnitLength.meters)
        return distanceFormatter.string(from: metres.converted(to: .kilometers)) + " away"
    }

    private static func makeDateFormatter(locale: Locale, timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    private static func makeDistanceFormatter(locale: Locale) -> MeasurementFormatter {
        let formatter = MeasurementFormatter()
        formatter.locale = locale
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter
    }
}
