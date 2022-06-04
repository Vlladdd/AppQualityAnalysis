//
//  AnalyzeViewController.swift
//  AppQualityAnalysis
//
//  Created by Vlad Nechyporenko on 04.12.2021.
//

import UIKit
import iOSDropDown
import Charts

//VC that controls view where user can analyze his app
class AnalyzeViewController: UIViewController, ChartViewDelegate {

    //MARK: - View functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fileName.isHidden = true
        reviewsCount.isHidden = true
        appID.isHidden = true
        deleteButton.isEnabled = false
        alertController.addAction(UIAlertAction(title: "Ок", style: .default))
        makeSourceDropDown()
        makeGraphs()
        //some test data
        reviewsCount.text = "500"
        appID.text = "284882215"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        spinner.center = CGPoint(x: view.frame.midX, y: view.frame.midY)
        source.optionArray = constants.availableSources
        for reportName in reportModel.getReportsNames(username: userModel.currentUser!.nickname){
            source.optionArray.append(reportName)
        }
        userModel.createAction(date: Date(), userAction: "Visited analyze page")
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        spinner.center = CGPoint(x: view.frame.midY, y: view.frame.midX)
    }
    
    //MARK: - Properties
    
    private typealias constants = AnalyzeVC_Constants
    
    var userModel: UserModel!
    
    private let alertController = UIAlertController(title: "Error", message: "Hello, world!", preferredStyle: .alert)
    private let reportModel = ReportModel()
    
    private lazy var spinner = makeSpinner()
    
    @IBOutlet var graphs: [BarChartView]!
    
    @IBOutlet weak var graph1: BarChartView!
    @IBOutlet weak var graph2: BarChartView!
    @IBOutlet weak var graph3: BarChartView!
    @IBOutlet weak var graph4: BarChartView!
    @IBOutlet weak var graph5: BarChartView!
    @IBOutlet weak var graph6: BarChartView!
    @IBOutlet weak var source: DropDown!
    @IBOutlet weak var buttonStack: UIStackView!
    @IBOutlet weak var fileName: UITextField!
    @IBOutlet weak var result: UILabel!
    @IBOutlet weak var reviewsCount: UITextField!
    @IBOutlet weak var appID: UITextField!
    @IBOutlet weak var analyzeButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    //MARK: - Buttons Functions
    
    @IBAction func analyze(_ sender: UIButton) {
        analyzeButton.isEnabled = false
        view.addSubview(spinner)
        let reviewModel = ReviewModel()
        let metricModel = MetricModel()
        let originOfData = checkFields()
        let appID = appID.text!
        let fileName = fileName.text!
        let reviewsCount = reviewsCount.text!
        DispatchQueue.global().async {[weak self] in
            if let self = self {
                switch originOfData {
                case .database:
                    reviewModel.findReviews(appID: appID)
                    self.getAndSaveMetrics(reviewModel: reviewModel, fileName: fileName, appID: appID)
                case .appStore:
                    //        reviews.getReviewsFromAppStore(numPages: 10, appId: "324684580")
                    //        reviews.getReviewsFromAppStore(numPages: 8, appId: "880047117")
                    //        reviews.getReviewsFromAppStore(numPages: 2, appId: "603527166")
                    //        reviews.getReviewsFromAppStore(numPages: 10, appId: "564177498")
                    reviewModel.getReviewsFromAppStore(count: Int(reviewsCount)!, appId: appID, completion: {originOfData in
                        switch originOfData {
                        case .appStore:
                            self.getAndSaveMetrics(reviewModel: reviewModel, fileName: fileName, appID: appID)
                        case .failure(let description):
                            DispatchQueue.main.async {
                                self.showAlert(message: description)
                            }
                        default:
                            DispatchQueue.main.async {
                                self.showAlert(message: "Something went wrong!")
                            }
                        }
                    })
                case .report:
                    metricModel.findMetrics(reportName: self.reportModel.currentReport!.name, username: self.userModel.currentUser!.nickname)
                    DispatchQueue.main.async {[weak self] in
                        if let self = self {
                            self.updateUI(metricModel: metricModel)
                        }
                    }
                case .failure(let description):
                    DispatchQueue.main.async {
                        self.showAlert(message: description)
                    }
                }
            }
        }
    }
    
    @IBAction func deleteReport(_ sender: UIButton) {
        deleteButton.isEnabled = false
        reportModel.deleteReport(name: source.text!, username: userModel.currentUser!.nickname)
        if let index = source.optionArray.firstIndex(where: {$0 == source.text!}) {
            source.optionArray.remove(at: index)
        }
        source.text! = ""
    }
    
    //MARK: - Local Functions
    
    private func showAlert(message: String) {
        alertController.message = message
        present(alertController, animated: true, completion: nil)
        analyzeButton.isEnabled = true
        spinner.removeFromSuperview()
    }

    //check whether result is good or bad
    private func checkResult(metricModel: MetricModel) {
        switch metricModel.checkResult() {
        case .good:
            result.textColor = constants.goodColor
        case .notBad:
            result.textColor = constants.notBadColor
        case .bad:
            result.textColor = constants.badColor
        }
    }
    
    //builds graphs
    private func setGraphs(metricModel: MetricModel) {
        let b5Metrics_1 = Array(metricModel.getMetricsFromLevel(level: 5).dropLast(constants.metricsOnGraph * 2))
        let b5Metrics_2 = Array(Array(metricModel.getMetricsFromLevel(level: 5).dropLast(constants.metricsOnGraph)).dropFirst(constants.metricsOnGraph))
        let b5Metrics_3 = Array(metricModel.getMetricsFromLevel(level: 5).dropFirst(constants.metricsOnGraph * 2))
        setGraph(graph: graph1, metrics: metricModel.getMetricsFromLevel(level: 2))
        setGraph(graph: graph2, metrics: metricModel.getMetricsFromLevel(level: 3))
        setGraph(graph: graph3, metrics: metricModel.getMetricsFromLevel(level: 4))
        setGraph(graph: graph4, metrics: b5Metrics_1)
        setGraph(graph: graph5, metrics: b5Metrics_2)
        setGraph(graph: graph6, metrics: b5Metrics_3)
    }
    
    //builds graph with metrics values
    private func setGraph(graph: BarChartView, metrics: [MetricBlank]) {
        let metricsValues = getValues(from: metrics)
        let chartDataSetTotal = BarChartDataSet(entries: metricsValues.dataEntriesTotal, label: "Value")
        let chartDataSetMax = BarChartDataSet(entries: metricsValues.dataEntriesMax, label: "Max Value")
        let dataSets: [BarChartDataSet] = [chartDataSetTotal,chartDataSetMax]
        chartDataSetTotal.setColor(constants.dataSetColors[0])
        chartDataSetMax.setColor(constants.dataSetColors[1])
        let chartData = BarChartData(dataSets: dataSets)
        chartData.barWidth = constants.barWidth
        chartData.groupBars(fromX: constants.groupStartPoint, groupSpace: constants.groupSpace, barSpace: constants.barSpace)
        let groupWidth = chartData.groupWidth(groupSpace: constants.groupSpace, barSpace: constants.barSpace)
        graph.xAxis.labelFont = constants.font
        graph.xAxis.drawGridLinesEnabled = constants.xAxis.drawGridLinesEnabled
        graph.xAxis.labelPosition = constants.xAxis.labelPosition
        graph.xAxis.centerAxisLabelsEnabled = constants.xAxis.centerAxisLabelsEnabled
        graph.xAxis.granularity = constants.xAxis.granularity
        graph.xAxis.axisMinimum = constants.xAxis.axisMinimum
        graph.xAxis.valueFormatter = IndexAxisValueFormatter(values: metricsValues.metricsNames)
        graph.xAxis.axisMaximum = groupWidth * Double(metrics.count)
        graph.notifyDataSetChanged()
        graph.data = chartData
        graph.data!.setValueFormatter(DefaultValueFormatter(formatter: constants.numberFormatter))
        graph.animate(xAxisDuration: constants.chartAnimationDuration, yAxisDuration: constants.chartAnimationDuration, easingOption: constants.chartAnimation)
    }
    
    private func getValues(from metrics: [MetricBlank]) -> (dataEntriesTotal: [BarChartDataEntry], dataEntriesMax: [BarChartDataEntry], metricsNames: [String]) {
        var dataEntriesTotal: [BarChartDataEntry] = []
        var dataEntriesMax: [BarChartDataEntry] = []
        var metricsNames = [String]()
        var index = 0
        for metric in metrics {
            metricsNames.append(metric.name)
            let dataEntryTotal = BarChartDataEntry(x: Double(index) , y: metric.value.rounded(toPlaces: 1))
            let dataEntryMax = BarChartDataEntry(x: Double(index) , y: metric.maxValue.rounded(toPlaces: 1))
            dataEntriesTotal.append(dataEntryTotal)
            dataEntriesMax.append(dataEntryMax)
            index += 1
        }
        return (dataEntriesTotal, dataEntriesMax, metricsNames)
    }
    
    //configures graphs
    private func makeGraphs() {
        constants.makeGraph(graph: graph1, delegate: self)
        constants.makeGraph(graph: graph2, delegate: self)
        constants.makeGraph(graph: graph3, delegate: self)
        constants.makeGraph(graph: graph4, delegate: self)
        constants.makeGraph(graph: graph5, delegate: self)
        constants.makeGraph(graph: graph6, delegate: self)
    }
    
    private func makeSourceDropDown() {
        source.optionArray = constants.availableSources
        source.listDidDisappear {[weak self] in
            if let self = self {
                if !constants.availableSources.contains(self.source.text!) {
                    self.fileName.isHidden = true
                    self.reviewsCount.isHidden = true
                    self.appID.isHidden = true
                    if self.source.text!.isEmpty == false {
                        self.deleteButton.isEnabled = true
                    }
                    else {
                        self.deleteButton.isEnabled = false
                    }
                }
                else {
                    self.deleteButton.isEnabled = false
                    self.fileName.isHidden = false
                    self.reviewsCount.isHidden = false
                    self.appID.isHidden = false
                }
            }
        }
    }
    
    private func getAndSaveMetrics(reviewModel: ReviewModel, fileName: String, appID: String) {
        let metricModel = MetricModel()
        metricModel.reviewsByCategories = reviewModel.reviewsByCategories
        metricModel.getMetrics()
        reportModel.createReport(name: fileName, appID: appID, date: Date(), user: userModel.currentUser!)
        metricModel.saveMetrics(reportName: reportModel.currentReport!.name, username: userModel.currentUser!.nickname)
        DispatchQueue.main.async {[weak self] in
            if let self = self {
                self.source.optionArray.append(self.fileName.text!)
                self.updateUI(metricModel: metricModel)
            }
        }
    }
    
    //updates UI after calculations are finished
    private func updateUI(metricModel: MetricModel) {
        let totalResult = metricModel.getMetricValue(metricName: "M1d1")
        checkResult(metricModel: metricModel)
        result.text = "\(totalResult)"
        setGraphs(metricModel: metricModel)
        userModel.createAction(date: Date(), userAction: "Analyzed app from \(source.text!) with appID \(appID.text!) with \(reviewsCount.text!) reviews")
        analyzeButton.isEnabled = true
        spinner.removeFromSuperview()
    }
    
    //checks data in all fields
    private func checkFields() -> OriginOfData{
        let reviewModel = ReviewModel()
        var maxReviewsCount = 0
        if source.text == "App Store" {
            maxReviewsCount = constants.maxReviewsInAppStore
        }
        if source.text == "Database" {
            maxReviewsCount = reviewModel.reviewsCountInDB(appID: appID.text!)
        }
        
        if source.text! == "" {
            return .failure("Provide source!")
        }
        if (source.text! == "App Store" || source.text! == "Database") && (reviewsCount.text! == "" || appID.text! == "" || fileName.text! == "") {
            return .failure("Provide all data!")
        }
        else if source.text! == "App Store" || source.text! == "Database" {
            if Int(reviewsCount.text!) == nil {
                return .failure("Count must be number!")
            }
            else if reportModel.findReport(name: fileName.text!, username: userModel.currentUser!.nickname){
                return .failure("Filename already exists!")
            }
            else if source.text == "Database" && !reviewModel.checkAppIDinDatabase(appID: appID.text!){
                return .failure("Wrong AppID!")
            }
            else if Int(reviewsCount.text!)! > maxReviewsCount || Int(reviewsCount.text!)! < 0{
                return .failure("Count must be less then \(maxReviewsCount) and more than 0!")
            }
        }
        else {
            if !reportModel.findReport(name: source.text!, username: userModel.currentUser!.nickname){
                return .failure("Report doesnt exist!")
            }
        }
        
        if source.text == "App Store" {
            return .appStore
        }
        else if source.text == "Database" {
            return .database
        }
        else {
            return .report
        }
    }
    
}

//MARK: - Constants

private struct AnalyzeVC_Constants {
    
    static let fontSize: CGFloat = 10
    static let font = UIFont.systemFont(ofSize: fontSize)
    static let maxReviewsInAppStore = 500
    static let metricsOnGraph = 8
    static let goodColor = UIColor.green
    static let notBadColor = UIColor.orange
    static let badColor = UIColor.red
    static let chartAnimationDuration = 1.5
    static let chartAnimation = ChartEasingOption.linear
    static let barWidth = 0.3
    static let barSpace = 0.05
    static let groupStartPoint = 0.0
    static let groupSpace = 0.3
    static let availableSources = ["App Store", "Database"]
    static let dataSetColors = [UIColor.green, UIColor.red]
    
    static var numberFormatter: NumberFormatter {
        
        let numberFormatter = NumberFormatter()
        
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 1
        numberFormatter.groupingSeparator = ","
        numberFormatter.decimalSeparator = "."
        
        return numberFormatter
    }
    
    static var xAxis: XAxis {
        
        let xAxis = XAxis()
        
        xAxis.drawGridLinesEnabled = true
        xAxis.labelPosition = .bottom
        xAxis.centerAxisLabelsEnabled = true
        xAxis.granularity = 1
        xAxis.axisMinimum = 0
        
        return xAxis
    }
    
    static func makeGraph(graph: BarChartView, delegate: ChartViewDelegate) {
        
        let legend = graph.legend
        let yaxis = graph.leftAxis
        
        graph.delegate = delegate
        graph.noDataText = "You need to provide data for the chart."
        graph.rightAxis.enabled = false
        
        legend.enabled = true
        legend.horizontalAlignment = .right
        legend.verticalAlignment = .top
        legend.orientation = .vertical
        legend.drawInside = true
        legend.yOffset = 10.0
        legend.xOffset = 10.0
        legend.yEntrySpace = 0.0
        
        yaxis.spaceTop = 0.35
        yaxis.axisMinimum = 0
        yaxis.drawGridLinesEnabled = false
        
    }
}
