//
//  EventsListViewModelTests.swift
//  LocalEventsExplorerTests
//
//  Created by Navdeep Rana on 23/09/26.
//

import Combine
import EventsFeed
import XCTest
@testable import LocalEventsExplorer

@MainActor
final class EventsListViewModelTests: XCTestCase {

    func test_init_doesNotLoadEvents() {
        let (_, loader, _, _) = makeSUT()

        XCTAssertEqual(loader.loadCallCount, 0)
    }

    func test_load_requestsEventsAndBookmarks() {
        let (sut, loader, bookmarks, _) = makeSUT()

        sut.load()

        XCTAssertEqual(loader.loadCallCount, 1)
        XCTAssertEqual(bookmarks.receivedMessages, [.load])
    }

    func test_load_showsLoadingIndicatorUntilCompletion() {
        let (sut, loader, bookmarks, _) = makeSUT()

        sut.load()
        XCTAssertTrue(sut.isLoading, "Expected loading indicator once load starts")

        loader.completeLoading(with: [])
        bookmarks.completeLoad(with: [])
        XCTAssertFalse(sut.isLoading, "Expected no loading indicator once load completes")
    }

    func test_load_rendersEventsWithBookmarkState() {
        let event0 = makeEvent(title: "Jazz Night", locationName: "Massey Hall")
        let event1 = makeEvent(title: "Food Fest", locationName: "City Hall")
        let (sut, loader, bookmarks, _) = makeSUT()

        sut.load()
        loader.completeLoading(with: [event0, event1])
        bookmarks.completeLoad(with: [event1.id])

        XCTAssertEqual(sut.events.map(\.title), ["Jazz Night", "Food Fest"])
        XCTAssertEqual(sut.events.map(\.locationName), ["Massey Hall", "City Hall"])
        XCTAssertEqual(sut.events.map(\.isBookmarked), [false, true])
        XCTAssertEqual(sut.events.map(\.imageURL), [event0.imageURL, event1.imageURL])
        XCTAssertEqual(sut.events[0].dateText, expectedDateText(for: event0.time))
        XCTAssertNil(sut.events[0].distanceText, "Expected no distance before a user location is known")
        XCTAssertNil(sut.errorMessage)
    }

    func test_load_showsErrorMessageAndKeepsPreviousEventsOnLoaderFailure() {
        let event = makeEvent()
        let (sut, loader, bookmarks, _) = makeSUT()

        sut.load()
        loader.completeLoading(with: [event])
        bookmarks.completeLoad(with: [])

        sut.load()
        loader.completeLoading(with: anyNSError(), at: 1)

        XCTAssertEqual(sut.events.map(\.id), [event.id])
        XCTAssertEqual(sut.errorMessage, EventsListViewModel.loadErrorMessage)
        XCTAssertFalse(sut.isLoading)
    }

    func test_load_clearsPreviousErrorMessage() {
        let (sut, loader, bookmarks, _) = makeSUT()

        sut.load()
        loader.completeLoading(with: anyNSError())
        XCTAssertNotNil(sut.errorMessage)

        sut.load()
        XCTAssertNil(sut.errorMessage)
        loader.completeLoading(with: [], at: 1)
        bookmarks.completeLoad(with: [], at: 1)
    }

    func test_toggleBookmark_updatesStateAndPersistsIt() {
        let event = makeEvent()
        let (sut, loader, bookmarks, _) = makeSUT()
        sut.load()
        loader.completeLoading(with: [event])
        bookmarks.completeLoad(with: [])

        sut.toggleBookmark(for: event.id)
        XCTAssertEqual(sut.events[0].isBookmarked, true)
        XCTAssertEqual(bookmarks.receivedMessages, [.load, .add(event.id)])

        sut.toggleBookmark(for: event.id)
        XCTAssertEqual(sut.events[0].isBookmarked, false)
        XCTAssertEqual(bookmarks.receivedMessages, [.load, .add(event.id), .remove(event.id)])
    }

    func test_toggleBookmark_revertsStateWhenPersistenceFails() {
        let event = makeEvent()
        let (sut, loader, bookmarks, _) = makeSUT()
        sut.load()
        loader.completeLoading(with: [event])
        bookmarks.completeLoad(with: [])

        sut.toggleBookmark(for: event.id)
        bookmarks.completeUpdate(with: anyNSError())

        XCTAssertEqual(sut.events[0].isBookmarked, false)
    }

    func test_showsBookmarkedOnly_filtersVisibleEvents() {
        let event0 = makeEvent()
        let event1 = makeEvent()
        let (sut, loader, bookmarks, _) = makeSUT()
        sut.load()
        loader.completeLoading(with: [event0, event1])
        bookmarks.completeLoad(with: [event1.id])

        XCTAssertEqual(sut.visibleEvents.map(\.id), [event0.id, event1.id])

        sut.showsBookmarkedOnly = true
        XCTAssertEqual(sut.visibleEvents.map(\.id), [event1.id])
    }

    func test_startUpdatingLocation_requestsLocationAndRendersDistanceToEachEvent() {
        let masseyHall = makeEvent(latitude: 43.6544, longitude: -79.3792)
        let (sut, loader, bookmarks, location) = makeSUT()
        sut.load()
        loader.completeLoading(with: [masseyHall])
        bookmarks.completeLoad(with: [])

        sut.startUpdatingLocation()
        XCTAssertEqual(location.requestCallCount, 1)

        location.send(Location(latitude: 43.6426, longitude: -79.3871)) // CN Tower

        XCTAssertEqual(sut.events[0].distanceText, "1.5 km away")
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: EventsListViewModel, loader: EventsLoaderSpy, bookmarks: BookmarksRepositorySpy, location: LocationProviderStub) {
        let loader = EventsLoaderSpy()
        let bookmarks = BookmarksRepositorySpy()
        let location = LocationProviderStub()
        let sut = EventsListViewModel(
            eventsPublisher: loader.loadPublisher,
            bookmarks: bookmarks,
            locationProvider: location,
            locale: Locale(identifier: "en_US"),
            timeZone: TimeZone(identifier: "America/Toronto")!
        )
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(bookmarks, file: file, line: line)
        trackForMemoryLeaks(location, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader, bookmarks, location)
    }

    private func makeEvent(title: String = "any title", locationName: String = "any place", latitude: Double = 43.65, longitude: Double = -79.38) -> Event {
        return Event(
            id: UUID(),
            title: title,
            location: EventLocation(name: locationName, latitude: latitude, longitude: longitude),
            time: Date(timeIntervalSince1970: 1791070200), // 2026-10-03 19:30 Toronto
            imageURL: URL(string: "https://a-url.com/\(UUID().uuidString).jpg")!
        )
    }

    private func expectedDateText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = TimeZone(identifier: "America/Toronto")!
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }

    private class EventsLoaderSpy {
        private var requests = [PassthroughSubject<[Event], Error>]()

        var loadCallCount: Int { requests.count }

        func loadPublisher() -> AnyPublisher<[Event], Error> {
            let publisher = PassthroughSubject<[Event], Error>()
            requests.append(publisher)
            return publisher.eraseToAnyPublisher()
        }

        func completeLoading(with events: [Event], at index: Int = 0) {
            requests[index].send(events)
            requests[index].send(completion: .finished)
        }

        func completeLoading(with error: Error, at index: Int = 0) {
            requests[index].send(completion: .failure(error))
        }
    }

    private class BookmarksRepositorySpy: BookmarksRepository {
        enum Message: Equatable {
            case load
            case add(UUID)
            case remove(UUID)
        }

        private(set) var receivedMessages = [Message]()
        private var loadRequests = [PassthroughSubject<Set<UUID>, Error>]()
        private var updateRequests = [PassthroughSubject<Void, Error>]()

        func loadBookmarkedEventIDs() -> AnyPublisher<Set<UUID>, Error> {
            receivedMessages.append(.load)
            let publisher = PassthroughSubject<Set<UUID>, Error>()
            loadRequests.append(publisher)
            return publisher.eraseToAnyPublisher()
        }

        func addBookmark(for eventID: UUID) -> AnyPublisher<Void, Error> {
            receivedMessages.append(.add(eventID))
            return makeUpdatePublisher()
        }

        func removeBookmark(for eventID: UUID) -> AnyPublisher<Void, Error> {
            receivedMessages.append(.remove(eventID))
            return makeUpdatePublisher()
        }

        func completeLoad(with ids: Set<UUID>, at index: Int = 0) {
            loadRequests[index].send(ids)
            loadRequests[index].send(completion: .finished)
        }

        func completeUpdate(with error: Error, at index: Int = 0) {
            updateRequests[index].send(completion: .failure(error))
        }

        private func makeUpdatePublisher() -> AnyPublisher<Void, Error> {
            let publisher = PassthroughSubject<Void, Error>()
            updateRequests.append(publisher)
            return publisher.eraseToAnyPublisher()
        }
    }

    private class LocationProviderStub: LocationProvider {
        private let subject = CurrentValueSubject<Location?, Never>(nil)
        private(set) var requestCallCount = 0

        var locationPublisher: AnyPublisher<Location?, Never> { subject.eraseToAnyPublisher() }

        func requestLocation() {
            requestCallCount += 1
        }

        func send(_ location: Location) {
            subject.send(location)
        }
    }
}
