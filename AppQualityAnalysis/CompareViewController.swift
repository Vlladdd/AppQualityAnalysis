//
//  CompareViewController.swift
//  AppQualityAnalysis
//
//  Created by Vlad Nechiporenko on 07.12.2021.
//

import UIKit
import iOSDropDown
import Charts

class CompareViewController: UIViewController, ChartViewDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        source.optionArray = ["App Store", "Database"]
        makeGraph(myGraph: graph1)
        makeGraph(myGraph: graph2)
        makeGraph(myGraph: graph3)
        makeGraph(myGraph: graph4)
        makeGraph(myGraph: graph5)
        makeGraph(myGraph: graph6)
        appID.text = "284882215"
        reviewsCount.text = "500"
        version.text = "345.0"
        date.text = ""
        showDatePicker()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        actions.createAction(user: users.currentUser, date: Date(), userAction: "Visit compare page")
    }
    let datePicker = UIDatePicker()
    var users: Users!
    let actions = Actions()
    
    func showDatePicker(){
        //Formate Date
        datePicker.datePickerMode = .date
        
        //ToolBar
        let toolbar = UIToolbar();
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(donedatePicker));
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelDatePicker));
        
        toolbar.setItems([doneButton,spaceButton,cancelButton], animated: false)
        
        date.inputAccessoryView = toolbar
        date.inputView = datePicker
        
    }
    
    @objc func donedatePicker(){
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        date.text = formatter.string(from: datePicker.date)
        self.view.endEditing(true)
    }
    
    @objc func cancelDatePicker(){
        self.view.endEditing(true)
    }
    
    @IBOutlet weak var source: DropDown!
    @IBOutlet weak var date: UITextField!
    @IBOutlet weak var version: UITextField!
    @IBOutlet weak var appID: UITextField!
    @IBOutlet weak var result: UILabel!
    @IBOutlet weak var reviewsCount: UITextField!
    weak var axisFormatDelegate: IAxisValueFormatter?
    
    @IBOutlet weak var graph1: CombinedChartView!
    @IBOutlet weak var graph2: CombinedChartView!
    @IBOutlet weak var graph3: CombinedChartView!
    @IBOutlet weak var graph4: CombinedChartView!
    @IBOutlet weak var graph5: CombinedChartView!
    @IBOutlet weak var graph6: CombinedChartView!
    
    @IBAction func analyze(_ sender: UIButton) {
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
        let filteredReviews = Reviews()
        let filteredMetrics = Metrics()
        let alertController = UIAlertController(title: "Error", message: "Hello, world!", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ок", style: .default))
        if source.text! == "" || reviewsCount.text! == "" || appID.text! == "" && (date.text! == "" || version.text! == ""){
            alertController.message = "Provide all data!"
            present(alertController, animated: true, completion: nil)
        }
        else if range != nil {
            alertController.message = "Count must be number!"
            present(alertController, animated: true, completion: nil)
        }
        else if source.text == "App Store" && !reviews.checkAppID(appID: appID.text!){
            alertController.message = "Wrong AppID!"
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

        
        if source.text! != "" && Int(reviewsCount.text!) ?? maxReviewsCount + 1 <= maxReviewsCount {
            if source.text == "Database" && reviews.checkAppIDDatabase(appID: appID.text!) {
                reviews.findReviews(appID: appID.text!)
                reviews.reviews = reviews.reviews.dropLast(maxReviewsCount - Int(reviewsCount.text!)!)
            }
            if source.text == "App Store" && reviews.checkAppID(appID: appID.text!){
                reviews.getReviewsFromAppStore(numPages: Int(reviewsCount.text!)!/50 , appId: appID.text!)
                reviews.reviews = reviews.reviews.dropLast(maxReviewsCount - Int(reviewsCount.text!)!)
            }
            //        reviews.getReviewsFromAppStore(numPages: 10, appId: "324684580")
            //        reviews.getReviewsFromAppStore(numPages: 8, appId: "880047117")
            //        reviews.getReviewsFromAppStore(numPages: 2, appId: "603527166")
            //        reviews.getReviewsFromAppStore(numPages: 10, appId: "564177498")
            filteredReviews.reviews = reviews.reviews
            if reviews.checkDate(date: date.text!) || reviews.checkVersion(version: version.text!) {
                filteredReviews.filterReviews(date: date.text!, version: version.text!)
                reviews.sortReviewsByCategories()
                filteredReviews.sortReviewsByCategories()
                metrics.reviewsByCategories = reviews.reviewsByCategories
                metrics.getMetrics()
                filteredMetrics.reviewsByCategories = filteredReviews.reviewsByCategories
                filteredMetrics.getMetrics()
                switch filteredMetrics.checkResult() {
                case 1:
                    result.textColor = UIColor.green
                case 2:
                    result.textColor = UIColor.orange
                case 3:
                    result.textColor = UIColor.red
                default:
                    result.textColor = UIColor.green
                }
                let totalResult = filteredMetrics.getMetricValue(metricName: "M1d1")
                result.text = "\(round(1000 * totalResult)/1000)"
                
                setChart(myGraph: graph1, metrics: metrics.getMetricLevel(metricLevel: "d2"), filteredMetrics: filteredMetrics.getMetricLevel(metricLevel: "d2"))
                setChart(myGraph: graph2, metrics: metrics.getMetricLevel(metricLevel: "d3"), filteredMetrics: filteredMetrics.getMetricLevel(metricLevel: "d3"))
                setChart(myGraph: graph3, metrics: metrics.getMetricLevel(metricLevel: "d4"), filteredMetrics: filteredMetrics.getMetricLevel(metricLevel: "d4"))
                setChart(myGraph: graph4, metrics: metrics.getMetricLevel(metricLevel: "b5").dropLast(8), filteredMetrics: filteredMetrics.getMetricLevel(metricLevel: "b5").dropLast(8))
                setChart(myGraph: graph5, metrics: Array(metrics.getMetricLevel(metricLevel: "b5").dropFirst(8)), filteredMetrics: Array(filteredMetrics.getMetricLevel(metricLevel: "b5").dropFirst(8)))
                setChart(myGraph: graph6, metrics: metrics.getMetricLevel(metricLevel: "_b5"), filteredMetrics: filteredMetrics.getMetricLevel(metricLevel: "_b5"))
                
                
                actions.createAction(user: users.currentUser, date: Date(), userAction: "Analyze app from \(source.text!) with appID \(appID.text!) with \(reviewsCount.text!) reviews with parameters: date:\(date.text!) version:\(version.text!)")
            }
            else {
                alertController.message = "Wrong version or date!"
                present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func setChart(myGraph: CombinedChartView, metrics: [Metric], filteredMetrics: [Metric]) {
        let graph = myGraph
        var dataEntries: [BarChartDataEntry] = []
        var dataEntries1: [BarChartDataEntry] = []
        var dataEntries2: [ChartDataEntry] = []
        var dataEntries3: [ChartDataEntry] = []
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.maximumFractionDigits = 1
        fmt.groupingSeparator = ","
        fmt.decimalSeparator = "."
        var i = 0
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
        
        for metric in metrics {
            
            let dataEntry = BarChartDataEntry(x: Double(i) , y: metric.value)
            dataEntries.append(dataEntry)
            
            let dataEntry1 = BarChartDataEntry(x: Double(i) , y: metric.maxValue)
            dataEntries1.append(dataEntry1)
            
            //stack barchart
            //let dataEntry = BarChartDataEntry(x: Double(i), yValues:  [self.unitsSold[i],self.unitsBought[i]], label: "groupChart")
            
            i += 1
            
        }
        
        i = 0
        
        for metric in filteredMetrics {
            
            let dataEntry2 = ChartDataEntry(x: Double(i) , y: metric.value)
            dataEntries2.append(dataEntry2)
            
            let dataEntry3 = ChartDataEntry(x: Double(i) , y: metric.maxValue)
            dataEntries3.append(dataEntry3)
            
            //stack barchart
            //let dataEntry = BarChartDataEntry(x: Double(i), yValues:  [self.unitsSold[i],self.unitsBought[i]], label: "groupChart")
            
            i += 1
            
        }
        
        let chartDataSet = BarChartDataSet(entries: dataEntries, label: "Value")
        let chartDataSet1 = BarChartDataSet(entries: dataEntries1, label: "Max Value")
        
        let dataSets: [BarChartDataSet] = [chartDataSet,chartDataSet1]
        let lineChartSet = LineChartDataSet(entries: dataEntries2, label: "")
        lineChartSet.colors = [UIColor(red: 230/255, green: 126/255, blue: 34/255, alpha: 1)]
        lineChartSet.circleColors = [UIColor(red: 230/255, green: 126/255, blue: 34/255, alpha: 1)]
        let lineChartSet2 = LineChartDataSet(entries: dataEntries3, label: "")
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
        print("Groupspace: \(gg)")
        graph.xAxis.axisMaximum = Double(startYear) + gg * Double(groupCount)
        
        chartData.groupBars(fromX: Double(startYear), groupSpace: groupSpace, barSpace: barSpace)
        //chartData.groupWidth(groupSpace: groupSpace, barSpace: barSpace)
        graph.notifyDataSetChanged()
        
        let data: CombinedChartData = CombinedChartData()
        data.barData = chartData
        data.lineData = LineChartData(dataSets: [lineChartSet,lineChartSet2])
        
        graph.data = data
        
        
        graph.legend.entries.remove(at: 0)
        graph.legend.entries.remove(at: 0)
        
        graph.data!.setValueFormatter(DefaultValueFormatter(formatter:fmt))
        
        
        
        
        
        //background color
        graph.backgroundColor = UIColor(red: 189/255, green: 195/255, blue: 199/255, alpha: 1)
        
        //chart animation
        graph.animate(xAxisDuration: 1.5, yAxisDuration: 1.5, easingOption: .linear)
        
        
    }
    
    func makeGraph(myGraph: CombinedChartView) {
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
