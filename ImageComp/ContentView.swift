//
//  ContentView.swift
//  ImageComp
//
//  Created by Lukáš Budáč on 04/03/2024.
//

import Kingfisher
import SwiftUI

// TEST CASE: single
//
// format: avif || testSource: disk || runs: 1 || totalMs: 269 || AVG: 269.0
// format: webp || testSource: disk || runs: 1 || totalMs: 282 || AVG: 282.0
// format: jpg || testSource: disk || runs: 1 || totalMs: 457 || AVG: 457.0
//
// format: avif || testSource: memory || runs: 1 || totalMs: 19 || AVG: 19.0
// format: webp || testSource: memory || runs: 1 || totalMs: 20 || AVG: 20.0
// format: jpg || testSource: memory || runs: 1 || totalMs: 19 || AVG: 19.0
//
// format: avif || testSource: net || runs: 1 || totalMs: 1542 || AVG: 1542.0
// format: webp || testSource: net || runs: 1 || totalMs: 1756 || AVG: 1756.0
// format: jpg || testSource: net || runs: 1 || totalMs: 2526 || AVG: 2526.0
//
// TEST CASE: singleRepeated
//
// format: avif || testSource: disk || runs: 100 || totalMs: 20668 || AVG: 206.68
// format: webp || testSource: disk || runs: 100 || totalMs: 20410 || AVG: 204.1
// format: jpg || testSource: disk || runs: 100 || totalMs: 40092 || AVG: 400.92
//
// format: avif || testSource: memory || runs: 100 || totalMs: 1872 || AVG: 18.72
// format: webp || testSource: memory || runs: 100 || totalMs: 1911 || AVG: 19.11
// format: jpg || testSource: memory || runs: 100 || totalMs: 1916 || AVG: 19.16
//
// format: avif || testSource: net || runs: 100 || totalMs: 145112 || AVG: 1451.12
// format: webp || testSource: net || runs: 100 || totalMs: 153518 || AVG: 1535.18
// format: jpg || testSource: net || runs: 100 || totalMs: 237374 || AVG: 2373.74
//
// TEST CASE: multiple
//
// format: avif || testSource: disk || runs: 100 || totalMs: 28976 || AVG: 289.76
// format: webp || testSource: disk || runs: 100 || totalMs: 33585 || AVG: 335.85
// format: jpg || testSource: disk || runs: 100 || totalMs: 50599 || AVG: 505.99
//
// format: avif || testSource: memory || runs: 100 || totalMs: 7469 || AVG: 74.69
// format: webp || testSource: memory || runs: 100 || totalMs: 7580 || AVG: 75.8
// format: jpg || testSource: memory || runs: 100 || totalMs: 7574 || AVG: 75.74
//
// format: avif || testSource: net || runs: 100 || totalMs: 183446 || AVG: 1834.46
// format: webp || testSource: net || runs: 100 || totalMs: 190662 || AVG: 1906.62
// format: jpg || testSource: net || runs: 100 || totalMs: 244810 || AVG: 2448.1
//
// TEST CASE: multiple repeated
//
// format: avif || testSource: disk || runs: 10000 || totalMs: 2472042 || AVG: 247.2042
// format: webp || testSource: disk || runs: 10000 || totalMs: 2445656 || AVG: 244.5656
// format: jpg || testSource: disk || runs: 10000 || totalMs: 4389869 || AVG: 438.9869
//
// format: avif || testSource: memory || runs: 10000 || totalMs: 742985 || AVG: 74.2985
// format: webp || testSource: memory || runs: 10000 || totalMs: 739862 || AVG: 73.9862
// format: jpg || testSource: memory || runs: 10000 || totalMs: 752224 || AVG: 75.2224
//
// format: avif || testSource: net || runs: 10000 || totalMs: 25066891 || AVG: 2506.6892
// format: webp || testSource: net || runs: 10000 || totalMs: 22883429 || AVG: 2288.3428
// format: jpg || testSource: net || runs: 10000 || totalMs: 30716096 || AVG: 3071.6096

let testImage = TestImage.jpg
let testRuns = 100
let testSource = TestSource.net

enum TestCase: String {
	case single = "Single"
	case singleRepeated = "Single repeated"
	case multiple = "Multiple"
	case multipleRepeated = "Multiple repeated"
	case list = "List"
}

enum TestSource {
	case disk
	case memory
	case net
}

enum TestImage {
	case avif
	case webp
	case jpg

	var urlString: String {
		switch self {
		case .avif:
			"https://raw.githubusercontent.com/budacl/ImageComp/main/image_avif.avif"
		case .webp:
			"https://raw.githubusercontent.com/budacl/ImageComp/main/image_webp.webp"
		case .jpg:
			"https://raw.githubusercontent.com/budacl/ImageComp/main/image_jpg.jpg"
		}
	}

	var url: URL {
		URL(string: urlString)!
	}
}


struct ContentView: View {

	@State
	var isFetched = false

	@State
	private var path = NavigationPath()

	private static var run = 1
	private static var totalMs = 0

	private static var multipleImagesShown = 0

	var body: some View {
		NavigationStack(path: $path) {
			VStack(spacing: 20) {
				Button("Fetch") {
					fetch()
				}
				button(for: .single)
				button(for: .singleRepeated)
				button(for: .multiple)
				button(for: .multipleRepeated)
				button(for: .list)
			}
			.navigationDestination(for: String.self) { view in
				let _ = setupMemory()

				switch view {
				case TestCase.single.rawValue:
					DetailView(testImage: testImage) { ms in
						Self.totalMs += ms
						printResults()
					}

				case TestCase.singleRepeated.rawValue: 
					let _ = print("--> \(type(of: self)).\(#function) || run: \(Self.run) || testImage: \(testImage)")
					DetailView(testImage: testImage) { ms in
						Self.totalMs += ms
						if Self.run < testRuns {
							Task { @MainActor in
								Self.run += 1
								try? await Task.sleep(nanoseconds: 1_000_000_000)
								path.append(TestCase.singleRepeated.rawValue)
							}
						} else {
							printResults()
						}
					}

				case TestCase.multiple.rawValue:
					MultipleView(testImage: testImage) { ms in
						Self.totalMs += ms
						Self.run += 1
						if Self.run == MultipleView.testImagesCount {
							printResults()
						}
					}

				case TestCase.multipleRepeated.rawValue:
					let _ = print("--> \(type(of: self)).\(#function) || run: \(Self.run) || testImage: \(testImage)")
					MultipleView(testImage: testImage) { ms in
						Self.totalMs += ms
						Self.run += 1
						if Self.run == testRuns * MultipleView.testImagesCount {
							print("--> \(type(of: self)).\(#function) || END")
							printResults()
						} else if Self.run % MultipleView.testImagesCount == 0 {
							print("--> \(type(of: self)).\(#function) || RUN AGAIN || run: \(Self.run)")
							Task { @MainActor in
								try? await Task.sleep(nanoseconds: 1_000_000_000)
								path.append(TestCase.multipleRepeated.rawValue)
							}
						}
					}

				case TestCase.list.rawValue:
					ListView(testImage: testImage)

				default: EmptyView()
				}
			}
		}
	}

	private func button(for testCase: TestCase) -> some View {
		Button("Start \(testCase.rawValue)") {
			Self.run = 1
			Self.totalMs = 0
			path.append(testCase.rawValue)
		}
	}

	private func printResults() {
		print("--> \(type(of: self)).\(#function) || format: \(testImage) || testSource: \(testSource) || runs: \(Self.run) || totalMs: \(Self.totalMs) || AVG: \(Float(Self.totalMs) / Float(Self.run))")
	}

	private func setupMemory() {
		switch testSource {
		case .disk:
			ImageCache.default.memoryStorage.removeAll()
		case .memory: ()
		case .net:
			ImageCache.default.memoryStorage.removeAll()
			try? ImageCache.default.diskStorage.removeAll()
		}
	}

	private func fetch() {
		let urls = [
			TestImage.avif.url,
			TestImage.webp.url,
			TestImage.jpg.url
		]
		let prefetcher = ImagePrefetcher(urls: urls) {
			skippedResources, failedResources, completedResources in
			print("--> \(type(of: self)).\(#function) || ===")
			print("--> \(type(of: self)).\(#function) || prefetched:")

			skippedResources.forEach { resource in
				print("--> \(type(of: self)).\(#function) || SKIPPED || url: \(resource.downloadURL.absoluteString) || cacheKey: \(resource.cacheKey)")
			}

			failedResources.forEach { resource in
				print("--> \(type(of: self)).\(#function) || FAILED || url: \(resource.downloadURL.absoluteString) || cacheKey: \(resource.cacheKey)")
			}

			completedResources.forEach { resource in
				print("--> \(type(of: self)).\(#function) || COMPLETED: || url: \(resource.downloadURL.absoluteString) || cacheKey: \(resource.cacheKey)")
			}
			isFetched = true
			print("--> \(type(of: self)).\(#function) || ===")
		}
		prefetcher.start()
	}
}

class DetailViewDeinit {
	let id = String(UUID().uuidString.suffix(8))
	init() {
		print("--> \(type(of: self)).\(#function) || init || id: \(id)")
	}

	deinit {
		print("--> \(type(of: self)).\(#function) || deinit || id: \(id)")
	}
}

struct DetailView: View {

	@Environment(\.dismiss) var dismiss

	let testImage: TestImage
	let onDone: (Int) -> ()

	var body: some View {
		image(for: testImage)
			.padding()
	}

	private func image(for testImage: TestImage) -> some View {
		let _ = print("--> \(type(of: self)).\(#function) || start")
		let startTime = DispatchTime.now()

		return KFImage
			.url(testImage.url)
			.placeholder {
				Text("loading image")
			}
			.onSuccess {
				let endTime = DispatchTime.now()
				let ms = elapsed(startTime, endTime)
				print("--> \(type(of: self)).\(#function) || success: \(ms)ms || source: \($0.cacheType)")
				dismiss()
				onDone(ms)
			}
			.onFailure {
				print("--> \(type(of: self)).\(#function) || error: \($0)")
			}
	}

}

struct MultipleView: View {

	@Environment(\.dismiss) var dismiss

	let testImage: TestImage
	let onDone: (Int) -> ()
	static let testImagesCount = 100
	private static var testImagesSuccess = 0

	init(testImage: TestImage, onDone: @escaping (Int) -> Void) {
		self.testImage = testImage
		self.onDone = onDone
		Self.testImagesSuccess = 0
	}

	var body: some View {
		LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 0) {
			ForEach(1...Self.testImagesCount, id: \.self) { item in
				image(for: testImage)
					.frame(width: 50, height: 50, alignment: .center)
			}
		}
	}

	private func image(for testImage: TestImage) -> some View {
		let startTime = DispatchTime.now()

		return KFImage
			.url(testImage.url)
			.resizable()
			.placeholder {
				Text("loading image")
			}
			.onSuccess {
				let endTime = DispatchTime.now()
				let ms = elapsed(startTime, endTime)
				Self.testImagesSuccess += 1
				print("--> \(type(of: self)).\(#function) || success: \(ms)ms || source: \($0.cacheType)")
				if Self.testImagesSuccess == Self.testImagesCount {
					dismiss()
				}
				onDone(ms)
			}
			.onFailure {
				print("--> \(type(of: self)).\(#function) || error: \($0)")
				if Self.testImagesSuccess == Self.testImagesCount {
					dismiss()
				}
				onDone(0)

			}
			.aspectRatio(contentMode: .fill)
	}

}

struct ListView: View {

	@Environment(\.dismiss) var dismiss

	let testImage: TestImage

	var body: some View {
		List {
			ForEach(1...testRuns, id: \.self) { item in
				image(for: testImage)
					.frame(width: 50, height: 50, alignment: .center)
			}
		}
	}

	private func image(for testImage: TestImage) -> some View {
		let startTime = DispatchTime.now()

		return KFImage
			.url(testImage.url)
			.resizable()
			.placeholder {
				Text("loading image")
			}
			.onSuccess {
				let endTime = DispatchTime.now()
				let ms = elapsed(startTime, endTime)
				print("--> \(type(of: self)).\(#function) || success: \(ms)ms || source: \($0.cacheType)")
			}
			.onFailure {
				print("--> \(type(of: self)).\(#function) || error: \($0)")
			}
			.aspectRatio(contentMode: .fill)
	}


}

#Preview {
	MultipleView(testImage: .avif, onDone: { _ in })
}

func elapsed(_ startTime: DispatchTime, _ endTime: DispatchTime) -> Int {
	let elapsedTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
	let elapsedTimeInMilliSeconds = Double(elapsedTime) / 1_000_000.0
	return Int(elapsedTimeInMilliSeconds)
}
