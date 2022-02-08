//
//  AnalyzeViewController.swift
//  AppQualityAnalysis
//
//  Created by Vlad Nechiporenko on 04.12.2021.
//

import UIKit
import iOSDropDown
import Charts

class AnalyzeViewController: UIViewController, ChartViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        source.optionArray = ["App Store", "Database"]
        source.listDidDisappear {
            if self.source.text == "App Store" {
                self.fileName.isHidden = false
                self.reviewsCount.isHidden = false
                self.appID.isHidden = false
            }
            if self.source.text != "App Store" && self.source.text != "Database" {
                self.fileName.isHidden = true
                self.reviewsCount.isHidden = true
                self.appID.isHidden = true
            }
        }
        makeGraph(myGraph: graph1)
        makeGraph(myGraph: graph2)
        makeGraph(myGraph: graph3)
        makeGraph(myGraph: graph4)
        makeGraph(myGraph: graph5)
        makeGraph(myGraph: graph6)
        reviewsCount.text = "500"
        appID.text = "284882215"
    }
    override func viewDidAppear(_ animated: Bool) {
        for reportName in reports.getReportsNames(){
            if !source.optionArray.contains(reportName){
                source.optionArray.append(reportName)
            }
        }
        actions.createAction(user: users.currentUser, date: Date(), userAction: "Visit analyze page")
    }
    var users: Users!
    let actions = Actions()
    let reports = Reports()
    var metric = Metric()
    
    @IBOutlet var graphs: [BarChartView]!
    
    @IBOutlet weak var graph1: BarChartView!
    @IBOutlet weak var graph2: BarChartView!
    @IBOutlet weak var graph3: BarChartView!
    @IBOutlet weak var graph4: BarChartView!
    @IBOutlet weak var graph5: BarChartView!
    @IBOutlet weak var graph6: BarChartView!
    @IBOutlet weak var source: DropDown!
    
    @IBOutlet weak var fileName: UITextField!
    @IBOutlet weak var result: UILabel!
    @IBOutlet weak var reviewsCount: UITextField!
    weak var axisFormatDelegate: IAxisValueFormatter?
    @IBOutlet weak var appID: UITextField!
    @IBOutlet weak var analyzeButton: UIButton!
    
    @IBAction func analyze(_ sender: UIButton) {
        analyzeButton.isUserInteractionEnabled = false
        var maxReviewsCount = 0
        let letters = NSCharacterSet.letters
        let range = reviewsCount.text!.rangeOfCharacter(from: letters)
        if source.text == "App Store" {
            maxReviewsCount = 500
        }
        let reviews = Reviews()
        let metrics = Metrics()
        if source.text == "Database" {
            maxReviewsCount = reviews.reviewsCoundDB(appID: appID.text!)
        }
        let alertController = UIAlertController(title: "Error", message: "Hello, world!", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ок", style: .default))
        if source.text! == "" {
            alertController.message = "Provide source!"
            present(alertController, animated: true, completion: nil)
        }
        if (source.text! == "App Store" || source.text! == "Database") && (reviewsCount.text! == "" || appID.text! == "" || fileName.text! == "") {
            alertController.message = "Provide all data!"
            present(alertController, animated: true, completion: nil)
        }
        else if source.text! == "App Store" || source.text! == "Database" {
            if range != nil {
                alertController.message = "Count must be number!"
                present(alertController, animated: true, completion: nil)
            }
            else if source.text == "App Store" && !reviews.checkAppID(appID: appID.text!){
                alertController.message = "Wrong AppID!"
                present(alertController, animated: true, completion: nil)
            }
            else if reports.findReport(name: fileName.text!){
                alertController.message = "Filename already exists!"
                present(alertController, animated: true, completion: nil)
            }
            else if source.text == "Database" && !reviews.checkAppIDDatabase(appID: appID.text!){
                alertController.message = "Wrong AppID!"
                present(alertController, animated: true, completion: nil)
            }
            else if Int(reviewsCount.text!)! > maxReviewsCount {
                alertController.message = "Count must be less then \(maxReviewsCount)!"
                present(alertController, animated: true, completion: nil)
            }
        }
        
        if (source.text! == "App Store" && Int(reviewsCount.text!) ?? maxReviewsCount + 1 <= maxReviewsCount && reviews.checkAppID(appID: appID.text!) && fileName.text! != "" && !reports.findReport(name: fileName.text!)) || (source.text != "App Store" && source.text != "Database" && source.text != "") || (source.text! == "Database" && reviews.checkAppIDDatabase(appID: appID.text!) && Int(reviewsCount.text!) ?? maxReviewsCount + 1 <= maxReviewsCount && fileName.text! != "" && !reports.findReport(name: fileName.text!)){
            if source.text != "App Store" && source.text != "Database" {
                if reports.findReport(name: source.text!){
                    metric.findMetrics(report: reports.currentReport)
                }
                for metric in metric.currentMetrics{
                    metrics.metrics.append(Metric(metric.name, metric.value, metric.maxValue))
                }
            }
            else if source.text! == "App Store" && Int(reviewsCount.text!) ?? maxReviewsCount + 1 <= maxReviewsCount && reviews.checkAppID(appID: appID.text!) && fileName.text! != "" {
                reviews.getReviewsFromAppStore(numPages: Int(reviewsCount.text!)!/50 , appId: appID.text!)
                reviews.reviews = reviews.reviews.dropLast(maxReviewsCount - Int(reviewsCount.text!)!)
                //        reviews.getReviewsFromAppStore(numPages: 10, appId: "324684580")
                //        reviews.getReviewsFromAppStore(numPages: 8, appId: "880047117")
                //        reviews.getReviewsFromAppStore(numPages: 2, appId: "603527166")
                //        reviews.getReviewsFromAppStore(numPages: 10, appId: "564177498")
                reviews.createReviews()
                reviews.sortReviewsByCategories()
                metrics.reviewsByCategories = reviews.reviewsByCategories
                metrics.getMetrics()
                reports.createReport(name: fileName.text!, appID: appID.text!, date: Date(), user: users.currentUser)
            }
            else if source.text! == "Database" {
                reviews.findReviews(appID: appID.text!)
                reviews.reviews = reviews.reviews.dropLast(maxReviewsCount - Int(reviewsCount.text!)!)
                reviews.sortReviewsByCategories()
                metrics.reviewsByCategories = reviews.reviewsByCategories
                metrics.getMetrics()
                reports.createReport(name: fileName.text!, appID: appID.text!, date: Date(), user: users.currentUser)
            }
            switch metrics.checkResult() {
            case 1:
                result.textColor = UIColor.green
            case 2:
                result.textColor = UIColor.orange
            case 3:
                result.textColor = UIColor.red
            default:
                result.textColor = UIColor.green
            }
            let totalResult = metrics.getMetricValue(metricName: "M1d1")
            result.text = "\(round(1000 * totalResult)/1000)"
            setChart(myGraph: graph1, metrics: metrics.getMetricLevel(metricLevel: "d2"))
            setChart(myGraph: graph2, metrics: metrics.getMetricLevel(metricLevel: "d3"))
            setChart(myGraph: graph3, metrics: metrics.getMetricLevel(metricLevel: "d4"))
            setChart(myGraph: graph4, metrics: metrics.getMetricLevel(metricLevel: "b5").dropLast(8))
            setChart(myGraph: graph5, metrics: Array(metrics.getMetricLevel(metricLevel: "b5").dropFirst(8)))
            setChart(myGraph: graph6, metrics: metrics.getMetricLevel(metricLevel: "_b5"))

            actions.createAction(user: users.currentUser, date: Date(), userAction: "Analyze app from \(source.text!) with appID \(appID.text!) with \(reviewsCount.text!) reviews")
        }
        if source.text! == "App Store" || source.text! == "Database"{
            for metric in metrics.metrics {
                metric.createMetric(report: reports.currentReport)
            }
        }
        analyzeButton.isUserInteractionEnabled = true
    }
    
    func containsOnlyLetters(input: String) -> Bool {
       for chr in input {
          if (!(chr >= "a" && chr <= "z") && !(chr >= "A" && chr <= "Z") ) {
             return false
          }
       }
       return true
    }
    
    func setChart(myGraph: BarChartView, metrics: [Metric]) {
        let graph = myGraph
        var dataEntries: [BarChartDataEntry] = []
        var dataEntries1: [BarChartDataEntry] = []
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.maximumFractionDigits = 1
        fmt.groupingSeparator = ","
        fmt.decimalSeparator = "."
        
        var metricNames = [String]()
        
        for metric in metrics {
            if metric.name.count < 6 {
                metricNames.append(metric.name)
            }
            else {
                metricNames.append(String(metric.name.dropLast(2)))
            }
        }
        
        let xaxis = graph.xAxis
        xaxis.valueFormatter = axisFormatDelegate
        xaxis.drawGridLinesEnabled = true
        xaxis.labelPosition = .bottom
        xaxis.centerAxisLabelsEnabled = true
        xaxis.valueFormatter = IndexAxisValueFormatter(values:metricNames)
        xaxis.granularity = 1
        
        var i = 0
        
        for metric in metrics {
            
            let dataEntry = BarChartDataEntry(x: Double(i) , y: metric.value)
            dataEntries.append(dataEntry)
            
            let dataEntry1 = BarChartDataEntry(x: Double(i) , y: metric.maxValue)
            dataEntries1.append(dataEntry1)
            
            //stack barchart
            //let dataEntry = BarChartDataEntry(x: Double(i), yValues:  [self.unitsSold[i],self.unitsBought[i]], label: "groupChart")
            
            i += 1
            
        }
        
        let chartDataSet = BarChartDataSet(entries: dataEntries, label: "Value")
        let chartDataSet1 = BarChartDataSet(entries: dataEntries1, label: "Max Value")
        
        let dataSets: [BarChartDataSet] = [chartDataSet,chartDataSet1]
        chartDataSet.colors = [UIColor(red: 230/255, green: 126/255, blue: 34/255, alpha: 1)]
        //chartDataSet.colors = ChartColorTemplates.colorful()
        //let chartData = BarChartData(dataSet: chartDataSet)
        
        let chartData = BarChartData(dataSets: dataSets)
        
        let groupSpace = 0.3
        let barSpace = 0.05
        let barWidth = 0.3
        
        
        let groupCount = metrics.count
        let startYear = 0
        
        
        chartData.barWidth = barWidth;
        graph.xAxis.axisMinimum = Double(startYear)
        let gg = chartData.groupWidth(groupSpace: groupSpace, barSpace: barSpace)
        //print("Groupspace: \(gg)")
        graph.xAxis.axisMaximum = Double(startYear) + gg * Double(groupCount)
        
        chartData.groupBars(fromX: Double(startYear), groupSpace: groupSpace, barSpace: barSpace)
        //chartData.groupWidth(groupSpace: groupSpace, barSpace: barSpace)
        graph.notifyDataSetChanged()
        
        graph.data = chartData
        
        
        graph.data!.setValueFormatter(DefaultValueFormatter(formatter:fmt))
        
        
        
        
        
        //background color
        graph.backgroundColor = UIColor(red: 189/255, green: 195/255, blue: 199/255, alpha: 1)
        
        //chart animation
        graph.animate(xAxisDuration: 1.5, yAxisDuration: 1.5, easingOption: .linear)
        
        
    }
    
    func makeGraph(myGraph: BarChartView) {
        let graph = myGraph
        graph.delegate = self
        graph.noDataText = "You need to provide data for the chart."


        //legend
        let legend = graph.legend
        legend.enabled = true
        legend.horizontalAlignment = .right
        legend.verticalAlignment = .top
        legend.orientation = .vertical
        legend.drawInside = true
        legend.yOffset = 10.0
        legend.xOffset = 10.0
        legend.yEntrySpace = 0.0


        let leftAxisFormatter = NumberFormatter()
        leftAxisFormatter.maximumFractionDigits = 1

        let yaxis = graph.leftAxis
        yaxis.spaceTop = 0.35
        yaxis.axisMinimum = 0
        yaxis.drawGridLinesEnabled = false

        graph.rightAxis.enabled = false
       //axisFormatDelegate = self
    }
    
}
