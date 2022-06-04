//
//  CompareViewController.swift
//  AppQualityAnalysis
//
//  Created by Vlad Nechyporenko on 07.12.2021.
//

import UIKit
import iOSDropDown
import Charts

//VC that controls view where user can compare analyze results of his app
class CompareViewController: UIViewController, ChartViewDelegate {
    
    //MARK: - View functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        alertController.addAction(UIAlertAction(title: "Ок", style: .default))
        makeSourceDropDown()
        makeGraphs()
        addDatePicker()
        //some random data
        appID.text = "284882215"
        reviewsCount.text = "500"
        version.text = "345.0"
        date.text = ""
    }
    
    override func viewDidAppear(_ animated: Bool) {
        spinner.center = CGPoint(x: view.frame.midX, y: view.frame.midY)
        userModel.createAction(date: Date(), userAction: "Visited compare page")
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        spinner.center = CGPoint(x: view.frame.midY, y: view.frame.midX)
    }
    
    //MARK: - Properties
    
    private typealias constants = CompareVC_Constants
    
    private let datePicker = UIDatePicker()
    private let alertController = UIAlertController(title: "Error", message: "Hello, world!", preferredStyle: .alert)
    
    private lazy var spinner = makeSpinner()
    
    var userModel: UserModel!
    
    @IBOutlet weak var source: DropDown!
    @IBOutlet weak var date: UITextField!
    @IBOutlet weak var version: UITextField!
    @IBOutlet weak var appID: UITextField!
    @IBOutlet weak var result: UILabel!
    @IBOutlet weak var reviewsCount: UITextField!
    @IBOutlet weak var analyzeButton: UIButton!
    @IBOutlet weak var graph1: CombinedChartView!
    @IBOutlet weak var graph2: CombinedChartView!
    @IBOutlet weak var graph3: CombinedChartView!
    @IBOutlet weak var graph4: CombinedChartView!
    @IBOutlet weak var graph5: CombinedChartView!
    @IBOutlet weak var graph6: CombinedChartView!
    
    //MARK: - Buttons Functions
    
    @IBAction func analyze(_ sender: UIButton) {
        analyzeButton.isEnabled = false
        view.addSubview(spinner)
        let reviewModel = ReviewModel()
        let metricModel = MetricModel()
        let appID = appID.text!
        let reviewsCount = reviewsCount.text!
        let date = date.text!
        let version = version.text!
        let originOfData = self.checkFields()
        DispatchQueue.global().async {[weak self] in
            if let self = self {
                switch originOfData {
                case .database:
                    reviewModel.findReviews(appID: appID)
                    if reviewModel.checkDate(date: date) || reviewModel.checkVersion(version: version){
                        self.getMetrics(metricModel: metricModel, reviewModel: reviewModel, date: date, version: version)
                    }
                    else {
                        DispatchQueue.main.async {
                            self.showAlert(message: "Wrong version or date!")
                        }
                    }
                case .appStore:
                    //        reviews.getReviewsFromAppStore(numPages: 10, appId: "324684580")
                    //        reviews.getReviewsFromAppStore(numPages: 8, appId: "880047117")
                    //        reviews.getReviewsFromAppStore(numPages: 2, appId: "603527166")
                    //        reviews.getReviewsFromAppStore(numPages: 10, appId: "564177498")
                    reviewModel.getReviewsFromAppStore(count: Int(reviewsCount)!, appId: appID, completion: {originOfData in
                        switch originOfData {
                        case .appStore:
                            if reviewModel.checkDate(date: date) || reviewModel.checkVersion(version: version){
                                self.getMetrics(metricModel: metricModel, reviewModel: reviewModel, date: date, version: version)
                            }
                            else {
                                DispatchQueue.main.async {
                                    self.showAlert(message: "Wrong version or date!")
                                }
                            }
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
                case .failure(let description):
                    DispatchQueue.main.async {
                        self.showAlert(message: description)
                    }
                default:
                    DispatchQueue.main.async {
                        self.showAlert(message: "Something went wrong!")
                    }
                }
            }
        }
    }
    
    //MARK: - Local Functions
    
    private func showAlert(message: String) {
        alertController.message = message
        present(alertController, animated: true, completion: nil)
        analyzeButton.isEnabled = true
        spinner.removeFromSuperview()
    }
    
    //builds graph with metrics values
    private func setGraph(graph: CombinedChartView, metrics: [MetricBlank], filteredMetrics: [MetricBlank]) {
        let metricsValues = getValuesBarChart(from: metrics)
        let metricsValuesFiltered = getValuesChart(from: filteredMetrics)
        let chartDataSetTotal = BarChartDataSet(entries: metricsValues.dataEntriesTotal, label: "Value")
        let chartDataSetMax = BarChartDataSet(entries: metricsValues.dataEntriesMax, label: "Max Value")
        let chartDataSetTotalFiltered = LineChartDataSet(entries: metricsValuesFiltered.dataEntriesTotal, label: "Value")
        let chartDataSetMaxFiltered = LineChartDataSet(entries: metricsValuesFiltered.dataEntriesMax, label: "Max Value")
        chartDataSetTotalFiltered.setColor(constants.dataSetColors[0])
        chartDataSetTotalFiltered.setCircleColor(constants.dataSetColors[0])
        chartDataSetMaxFiltered.setColor(constants.dataSetColors[1])
        chartDataSetMaxFiltered.setCircleColor(constants.dataSetColors[1])
        let barChartDataSets: [BarChartDataSet] = [chartDataSetTotal,chartDataSetMax]
        chartDataSetTotal.setColor(constants.dataSetColors[0])
        chartDataSetMax.setColor(constants.dataSetColors[1])
        let barChartData = BarChartData(dataSets: barChartDataSets)
        barChartData.barWidth = constants.barWidth
        barChartData.groupBars(fromX: constants.groupStartPoint, groupSpace: constants.groupSpace, barSpace: constants.barSpace)
        let groupWidth = barChartData.groupWidth(groupSpace: constants.groupSpace, barSpace: constants.barSpace)
        graph.xAxis.drawGridLinesEnabled = constants.xAxis.drawGridLinesEnabled
        graph.xAxis.labelPosition = constants.xAxis.labelPosition
        graph.xAxis.centerAxisLabelsEnabled = constants.xAxis.centerAxisLabelsEnabled
        graph.xAxis.granularity = constants.xAxis.granularity
        graph.xAxis.axisMinimum = constants.xAxis.axisMinimum
        graph.xAxis.valueFormatter = IndexAxisValueFormatter(values: metricsValues.metricsNames)
        graph.xAxis.axisMaximum = groupWidth * Double(metrics.count)
        graph.xAxis.labelFont = constants.font
        let data: CombinedChartData = CombinedChartData()
        data.barData = barChartData
        data.lineData = LineChartData(dataSets: [chartDataSetTotalFiltered,chartDataSetMaxFiltered])
        graph.notifyDataSetChanged()
        graph.data = data
        graph.data!.setValueFormatter(DefaultValueFormatter(formatter: constants.numberFormatter))
        graph.animate(xAxisDuration: constants.chartAnimationDuration, yAxisDuration: constants.chartAnimationDuration, easingOption: constants.chartAnimation)
    }
    
    private func getValuesBarChart(from metrics: [MetricBlank]) -> (dataEntriesTotal: [BarChartDataEntry], dataEntriesMax: [BarChartDataEntry], metricsNames: [String]) {
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
    
    private func getValuesChart(from metrics: [MetricBlank]) -> (dataEntriesTotal: [ChartDataEntry], dataEntriesMax: [ChartDataEntry], metricsNames: [String]) {
        var dataEntriesTotal: [ChartDataEntry] = []
        var dataEntriesMax: [ChartDataEntry] = []
        var metricsNames = [String]()
        var index = 0
        for metric in metrics {
            metricsNames.append(metric.name)
            let dataEntryTotal = ChartDataEntry(x: Double(index) , y: metric.value.rounded(toPlaces: 1))
            let dataEntryMax = ChartDataEntry(x: Double(index) , y: metric.maxValue.rounded(toPlaces: 1))
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
    }
    
    private func getMetrics(metricModel: MetricModel, reviewModel: ReviewModel, date: String, version: String) {
        let metricModelFiltered = MetricModel()
        let reviewModelFiltered = ReviewModel()
        reviewModelFiltered.reviews = reviewModel.reviews
        reviewModelFiltered.filterReviews(date: date, version: version)
        metricModel.reviewsByCategories = reviewModel.reviewsByCategories
        metricModelFiltered.reviewsByCategories = reviewModelFiltered.reviewsByCategories
        metricModel.getMetrics()
        metricModelFiltered.getMetrics()
        DispatchQueue.main.async {[weak self] in
            if let self = self {
                self.updateUI(metricModel: metricModel, metricModelFiltered: metricModelFiltered)
            }
        }
    }
    
    //updates UI after calculations are finished
    private func updateUI(metricModel: MetricModel, metricModelFiltered: MetricModel) {
        let totalResult = metricModelFiltered.getMetricValue(metricName: "M1d1")
        checkResult(metricModel: metricModelFiltered)
        result.text = "\(totalResult)"
        setGraphs(metricModel: metricModel, metricModelFiltered: metricModelFiltered)
        userModel.createAction(date: Date(), userAction: "Analyzed app from \(source.text!) with appID \(appID.text!) with \(reviewsCount.text!) reviews and compare results with date \(date.text!) and version \(version.text!)")
        analyzeButton.isEnabled = true
        spinner.removeFromSuperview()
    }
    
    //builds graphs
    private func setGraphs(metricModel: MetricModel, metricModelFiltered: MetricModel) {
        let b5Metrics1_1 = Array(metricModel.getMetricsFromLevel(level: 5).dropLast(constants.metricsOnGraph * 2))
        let b5Metrics1_2 = Array(Array(metricModel.getMetricsFromLevel(level: 5).dropLast(constants.metricsOnGraph)).dropFirst(constants.metricsOnGraph))
        let b5Metrics1_3 = Array(metricModel.getMetricsFromLevel(level: 5).dropFirst(constants.metricsOnGraph * 2))
        let b5Metrics2_1 = Array(metricModelFiltered.getMetricsFromLevel(level: 5).dropLast(constants.metricsOnGraph * 2))
        let b5Metrics2_2 = Array(Array(metricModelFiltered.getMetricsFromLevel(level: 5).dropLast(constants.metricsOnGraph)).dropFirst(constants.metricsOnGraph))
        let b5Metrics2_3 = Array(metricModelFiltered.getMetricsFromLevel(level: 5).dropFirst(constants.metricsOnGraph * 2))
        setGraph(graph: graph1, metrics: metricModel.getMetricsFromLevel(level: 2), filteredMetrics: metricModelFiltered.getMetricsFromLevel(level: 2))
        setGraph(graph: graph2, metrics: metricModel.getMetricsFromLevel(level: 3), filteredMetrics: metricModelFiltered.getMetricsFromLevel(level: 3))
        setGraph(graph: graph3, metrics: metricModel.getMetricsFromLevel(level: 4), filteredMetrics: metricModelFiltered.getMetricsFromLevel(level: 4))
        setGraph(graph: graph4, metrics: b5Metrics1_1, filteredMetrics: b5Metrics2_1)
        setGraph(graph: graph5, metrics: b5Metrics1_2, filteredMetrics: b5Metrics2_2)
        setGraph(graph: graph6, metrics: b5Metrics1_3, filteredMetrics: b5Metrics2_3)
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
        if (source.text! == "App Store" || source.text! == "Database") && (reviewsCount.text! == "" || appID.text! == ""){
            return .failure("Provide all data!")
        }
        else if date.text! == "" && version.text! == ""{
            return .failure("Provide version or date !")
        }
        else if source.text! == "App Store" || source.text! == "Database" {
            if Int(reviewsCount.text!) == nil {
                return .failure("Count must be number!")
            }
            else if source.text == "Database" && !reviewModel.checkAppIDinDatabase(appID: appID.text!){
                return .failure("Wrong AppID!")
            }
            else if Int(reviewsCount.text!)! > maxReviewsCount || Int(reviewsCount.text!)! < 0{
                return .failure("Count must be less then \(maxReviewsCount) and more than 0!")
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
    
    //adds date picker to the view
    private func addDatePicker(){
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .inline
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneWithDatePicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelDatePicker))
        toolbar.setItems([doneButton,spaceButton,cancelButton], animated: false)
        date.inputAccessoryView = toolbar
        date.inputView = datePicker
    }
    
    @objc private func doneWithDatePicker(){
        date.text = constants.dateFormatter.string(from: datePicker.date)
        self.view.endEditing(true)
    }
    
    @objc private func cancelDatePicker(){
        self.view.endEditing(true)
    }
    
}

//MARK: - Constants

private struct CompareVC_Constants {
    
    static let fontSize: CGFloat = 10
    static let font = UIFont.systemFont(ofSize: fontSize)
    static let dateFormat = "dd/MM/yyyy"
    static var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        return dateFormatter
    }
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
    
    static func makeGraph(graph: CombinedChartView, delegate: ChartViewDelegate) {
        
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
