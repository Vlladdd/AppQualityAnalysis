//
//  AppQualityAnalysisTests.swift
//  AppQualityAnalysisTests
//
//  Created by Vlad Nechiporenko on 25.11.2021.
//

import XCTest
@testable import AppQualityAnalysis

class AppQualityAnalysisTests: XCTestCase {
    
    var metrics: MetricModel!
    var review: Review!
    var reviews: ReviewModel!
    
    override func setUp() {
        metrics = MetricModel()
        reviews = ReviewModel()
        metrics.reviewsByCategories = [String:[Review]]()
    }

    override func tearDown() {
        metrics = nil
        reviews = nil
    }

    func testCalculateReviewsValue() {
        review = Review("the app is bad", Date(), 2, "100","111")
        metrics.reviewsByCategories!["M1"] = [review]
        let value = metrics.calculateReviewsValue(metricName: "M1", coef: 1.0)
        var rightValue = false
        if value.value == 0.2 && value.maxValue == 1.0 {
            rightValue = true
        }
        XCTAssertNotEqual(rightValue, false, "Wrong calculations!")
    }
    
    func testCalculateReviewsValueZero() {
        review = Review("aaaaaaaaa", Date(), 2, "100","111")
        metrics.reviewsByCategories!["M1"] = [review]
        let value = metrics.calculateReviewsValue(metricName: "M1", coef: 1.0)
        var rightValue = false
        if value.value == 0 && value.maxValue == 1.0 {
            rightValue = true
        }
        XCTAssertNotEqual(rightValue, false, "Wrong calculations!")
    }
    
    func testCalculateReviewsFiltered() {
        reviews.reviews.append(Review("the app is bad", Date(), 2, "100","111"))
        reviews.reviews.append(Review("the app is bad", Date(), 2, "200","111"))
        reviews.reviews.append(Review("the app is bad", Date(), 2, "300","111"))
        reviews.filterReviews(version: "100")
        var rightValue = false
        if reviews.reviews.count == 1 {
            rightValue = true
        }
        XCTAssertNotEqual(rightValue, false, "Wrong calculations!")
    }
    
    func testCheckAppIDWrong() {
        XCTAssertNotEqual(reviews.checkAppIDinAppStore(appID: "0"), true, "Wrong calculations!")
    }
    
    func testCheckAppIDCorrect() {
        XCTAssertNotEqual(reviews.checkAppIDinAppStore(appID: "284882215"), false, "Wrong calculations!")
    }
    
    func testCheckDateWrong() {
        reviews.reviews.append(Review("the app is bad", Date(), 2, "100","111"))
        XCTAssertNotEqual(reviews.checkDate(date: ""), true, "Wrong calculations!")
    }
    
    func testCheckDateCorrect() {
        reviews.reviews.append(Review("the app is bad", Date(), 2, "100","111"))
        XCTAssertNotEqual(reviews.checkDate(date: "20/12/2021"), false, "Wrong calculations!")
    }
    
    func testCheckVersionWrong() {
        reviews.reviews.append(Review("the app is bad", Date(), 2, "100","111"))
        XCTAssertNotEqual(reviews.checkVersion(version: "1000"), true, "Wrong calculations!")
    }
    
    func testCheckVersionCorrect() {
        reviews.reviews.append(Review("the app is bad", Date(), 2, "100","111"))
        XCTAssertNotEqual(reviews.checkVersion(version: "100"), false, "Wrong calculations!")
    }
    
    func testFindReviewsCorrect() {
        reviews.findReviews(appID: "284882215")
        var result = false
        if reviews.reviews.count > 400 {
            result = true
        }
        XCTAssertNotEqual(result, false, "Wrong calculations!")
    }
    
    func testFindReviewsWrong() {
        reviews.findReviews(appID: "22")
        var result = false
        if reviews.reviews.count == 0 {
            result = true
        }
        XCTAssertNotEqual(result, false, "Wrong calculations!")
    }
    
    func testCheckAppIDDatabaseWrong() {
        XCTAssertNotEqual(reviews.checkAppIDinDatabase(appID: "0"), true, "Wrong calculations!")
    }
    
    func testCheckAppIDDatabaseCorrect() {
        XCTAssertNotEqual(reviews.checkAppIDinDatabase(appID: "284882215"), false, "Wrong calculations!")
    }
    
    func testCheckReviewsCountDatabaseWrong() {
        XCTAssertEqual(reviews.reviewsCountInDB(appID: "0"), 0, "Wrong calculations!")
    }
    
    func testCheckReviewsCountDatabaseCorrect() {
        XCTAssertNotEqual(reviews.reviewsCountInDB(appID: "284882215"), 0, "Wrong calculations!")
    }
    
    func testRatingCorrect() {
        XCTAssertEqual(metrics.ratingCoef(rating: 2), 0.8, "Wrong calculations!")
    }
    
    func testRatingWrong() {
        XCTAssertEqual(metrics.ratingCoef(rating: -2), 0.0, "Wrong calculations!")
    }
    
    func testLongCorrect() {
        XCTAssertEqual(metrics.longCoef(review: "abc"), 0.25, "Wrong calculations!")
    }
    
    func testMeaningCorrect() {
        XCTAssertEqual(metrics.meaningCoef(review: "the app is bad"), 1, "Wrong calculations!")
    }
    
    func testMeaningWrong() {
        XCTAssertEqual(metrics.meaningCoef(review: "aaaaaaaaaa"), 0, "Wrong calculations!")
    }
    
    func testCalculateMetricValue() {
        XCTAssertEqual(metrics.calculateMetricValue(coef1: 4, value1: 100, value2: 200, value3: 300, metricName: "d4"), 2400, "Wrong calculations!")
    }
    

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}

    

