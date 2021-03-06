//
//  MetricModel.swift
//  AppQualityAnalysis
//
//  Created by Vlad Nechyporenko on 09.11.2021.
//

import Foundation
import RealmSwift

//MARK: - Metric Blank

//blank classes/structs made for easier use of realm objects, because realm objects
//are thread save, but i want to use them in all threads
//there is other solutions for that, like ThreadSafeReference, but i like mine
//class that represents copy of Metric object in Realm
//it has to be a class, cuz it has childs
class MetricBlank: Equatable{
    
    var name: String
    var value: Double
    var maxValue: Double
    var level: Int
    var coeficient = 0
    var number = 0
    var childs: [MetricBlank] = []
    var reviewsCount = 0
    
    init(name: String, coeficient: Int = 0, level: Int, number: Int = 0, value: Double = 0.0, maxValue: Double = 0.0, childs: [MetricBlank] = []){
        self.name = name
        self.value = value
        self.maxValue = maxValue
        self.coeficient = coeficient
        self.level = level
        self.childs = childs
        self.number = number
    }
    
    static func == (lhs: MetricBlank, rhs: MetricBlank) -> Bool {
        lhs.name == rhs.name
    }
    
}

//MARK: - Metric

//class that represents Metric object in Realm
class Metric: EmbeddedObject{
    @Persisted var name: String
    @Persisted var value: Double
    @Persisted var maxValue: Double
    @Persisted var level: Int
}

//MARK: - Model of Metric

//class that represents model of Metric
class MetricModel {
    
    //MARK: - Properties
    
    var metrics = [MetricBlank]()
    var reviewsByCategories: [String:[ReviewBlank]]?
    
    //MARK: - Functions
    
    //calculates metrics values
    func getMetrics(){
        metrics = MetricModelConstants.getStartMetrics()
        var reviewsCount = 0
        if let reviewsByCategories = reviewsByCategories {
            for review in reviewsByCategories {
                for _ in review.value {
                    reviewsCount += 1
                }
            }
            for category in reviewsByCategories {
                if let metric = metrics.first(where: {$0.name == category.key}) {
                    metric.reviewsCount = category.value.count
                }
            }
            for metric in metrics {
                calculateMetricValue(metric: metric, totalReviews: reviewsCount)
            }
        }
    }
    
    //formulas to calculate metric value based on her level
    private func calculateMetricValue(metric: MetricBlank, totalReviews: Int){
        calculateReviewsCount(metric: metric)
        var value = 0.0
        var maxValue = 0.0
        if metric.level == 5{
            let coef2 = (Double(metric.reviewsCount)/Double(totalReviews) * Double(metric.coeficient))
            value = calculateReviewsValue(metricName: metric.name, coef: coef2).value
            maxValue = calculateReviewsValue(metricName: metric.name, coef: coef2).maxValue
        }
        else if metric.level == 4{
            value = Double(metric.coeficient) * (metric.childs[0].value + metric.childs[1].value + metric.childs[2].value)
            maxValue = Double(metric.coeficient) * (metric.childs[0].maxValue + metric.childs[1].maxValue + metric.childs[2].maxValue)
        }
        else if metric.level == 3{
            value = Double(metric.coeficient) * (metric.childs[0].value + metric.childs[1].value)
            maxValue = Double(metric.coeficient) * (metric.childs[0].maxValue + metric.childs[1].maxValue)
        }
        else if metric.level == 2{
            if metric.reviewsCount == 0 {
                value = (Double(metric.coeficient) * (metric.childs[0].value + metric.childs[1].value))/1.0
                maxValue = (Double(metric.coeficient) * (metric.childs[0].maxValue + metric.childs[1].maxValue))/1.0
            }
            else {
                value = (Double(metric.coeficient) * (metric.childs[0].value + metric.childs[1].value))/Double(metric.reviewsCount)
                maxValue = (Double(metric.coeficient) * (metric.childs[0].maxValue + metric.childs[1].maxValue))/Double(metric.reviewsCount)
            }
        }
        else if metric.level == 1{
            value = metric.childs[0].value + metric.childs[1].value + metric.childs[2].value + metric.childs[3].value
            value = metric.childs[0].value + metric.childs[1].maxValue + metric.childs[2].maxValue + metric.childs[3].maxValue
        }
        metric.value = value
        metric.maxValue = maxValue
    }
    
    //we need to use recursion here, but as long as all metrics are in order
    //we dont need that
    private func calculateReviewsCount(metric: MetricBlank) {
        if metric.level != 2 {
            for child in metric.childs {
                metric.reviewsCount += child.reviewsCount
            }
        }
        else if metric.number == 1 || metric.number == 3 {
            metric.reviewsCount = metric.childs[0].reviewsCount
        }
        else {
            metric.reviewsCount = metric.childs[1].reviewsCount
        }
    }
    
    //maxValue is when all reviews are as bad as possible
    private func calculateReviewsValue(metricName: String, coef: Double = 0.0) -> (value: Double, maxValue: Double){
        var value = 1.0
        var totalValue = 0.0
        var maxValue = 0.0
        if let reviewsByCategories = reviewsByCategories, let reviews = reviewsByCategories[metricName] {
            for review in reviews {
                value *= ratingCoef(rating: review.rating)
                value *= longCoef(review: review.text)
                value *= Double(meaningCoef(review: review.text))
                value *= coef
                totalValue += value
                value = 1.0
            }
            for _ in reviews {
                value *= coef
                maxValue += value
                value = 1.0
            }
        }
        return (value: totalValue, maxValue: maxValue)
    }
    
    private func ratingCoef(rating: Int) -> Double {
        switch rating {
        case MetricModelConstants.ratings[0]:
            return MetricModelConstants.ratingCoefs[0]
        case MetricModelConstants.ratings[1]:
            return MetricModelConstants.ratingCoefs[1]
        case MetricModelConstants.ratings[2]:
            return MetricModelConstants.ratingCoefs[2]
        case MetricModelConstants.ratings[3]:
            return MetricModelConstants.ratingCoefs[3]
        case MetricModelConstants.ratings[4]:
            return MetricModelConstants.ratingCoefs[4]
        default:
            return MetricModelConstants.ratingCoefs[4]
        }
    }
    
    private func longCoef(review: String) -> Double {
        var word = ""
        var wordsNumber = 0
        for character in review {
            if !MetricModelConstants.forbiddenSymbols.contains(String(character)) {
                word.append(character)
            }
            else if word.count > 0{
                word = ""
                wordsNumber += 1
            }
        }
        switch wordsNumber {
        case let x where x < MetricModelConstants.badWordsAmount:
            return MetricModelConstants.longCoefs[0]
        case let x where x > MetricModelConstants.badWordsAmount && x < MetricModelConstants.goodWordsAmount:
            return MetricModelConstants.longCoefs[1]
        case let x where x > MetricModelConstants.goodWordsAmount:
            return MetricModelConstants.longCoefs[2]
        default:
            return MetricModelConstants.longCoefs[0]
        }
    }
    
    //how meaninfull review is
    //we have a vocabulary, where each substring with 2 characters has a value (how much it was counted in the text)
    //(for the text we can use any book). Then we multiply our substrings values and get an nth root of the result, where
    //nth is symbols count in the review and compare that to the average result
    private func meaningCoef(review: String) -> Int{
        var testData = review
        testData = testData.removingWhitespaces().lowercased()
        var points = 1
        //used when we reach max Integer value
        var points2 = 0
        var avgPoints = 0
        var count = 1
        var substring = ""
        var pointsNeeded = 1
        //used when we reach max Integer value
        var pointsNeeded2 = 0
        for character in testData {
            substring += String(character)
            if substring.count == 2 {
                if MetricModelConstants.vocabulary.keys.contains(substring) {
                    if !(points > (Int.max / MetricModelConstants.vocabulary[substring]!))
                    {
                        points = points * MetricModelConstants.vocabulary[substring]!
                    }
                    else {
                        points2 += Int(nthroot(of: Double(points), at: Double(testData.count - 1)))
                        points = 1
                        points = points * MetricModelConstants.vocabulary[substring]!
                    }
                }
                substring = ""
            }
            count += 1
        }
        var value = 0
        for substring in MetricModelConstants.vocabulary {
            value += substring.value
        }
        avgPoints = value / MetricModelConstants.vocabulary.count
        for _ in 0...testData.count / 2 - 1 {
            if !(pointsNeeded > (Int.max / avgPoints))
            {
                pointsNeeded = pointsNeeded * avgPoints
            }
            else {
                pointsNeeded2 += Int(nthroot(of: Double(pointsNeeded), at: Double(testData.count - 1)))
                pointsNeeded = 1
                pointsNeeded = pointsNeeded * avgPoints
            }
        }
        pointsNeeded = Int(nthroot(of: Double(pointsNeeded), at: Double(testData.count - 1)))
        pointsNeeded = pointsNeeded + pointsNeeded2
        points = Int(nthroot(of: Double(points), at: Double(testData.count - 1)))
        points = points + points2
        if points >= pointsNeeded - 1{
            return 1
        }
        else {
            return 0
        }
    }
    
    //helper function
    private func nthroot(of value: Double,  at n: Double) -> Double {
        let multipleOf2 = abs(n.truncatingRemainder(dividingBy: 2)) == 1
        return value < 0 && multipleOf2 ? -pow(-value, 1/n) : pow(value, 1/n)
    }
    
    //checks total result
    func checkResult() -> Result {
        if let metric = metrics.first(where: {$0.level == 1}) {
            let result = metric.maxValue / metric.value
            if result > MetricModelConstants.goodTotalResult {
                return .good
            }
            if result > MetricModelConstants.badTotalResult && result < MetricModelConstants.goodTotalResult{
                return .notBad
            }
            if result < MetricModelConstants.badTotalResult {
                return .bad
            }
        }
        return .bad
    }
    
    func getMetricValue(metricName: String) -> Double {
        if let metric = metrics.first(where: {$0.name == metricName}) {
            return metric.value.rounded(toPlaces: 1)
        }
        return 0.0
    }
    
    func getMetricsFromLevel(level: Int) -> [MetricBlank] {
        return metrics.filter({$0.level == level})
    }
    
    func saveMetrics(reportName: String, username: String){
        let realm = try! Realm()
        let reports = realm.objects(Report.self)
        let findReports = reports.where {
            $0.name == reportName && $0.users.nickname == username
        }
        if findReports.count == 1 {
            try! realm.write {
                for metric in metrics {
                    let realmMetric = Metric()
                    realmMetric.name = metric.name
                    realmMetric.value = metric.value
                    realmMetric.maxValue = metric.maxValue
                    realmMetric.level = metric.level
                    findReports.first!.metrics.append(realmMetric)
                }
            }
        }
    }
    
    func findMetrics(reportName: String, username: String){
        let realm = try! Realm()
        let reports = realm.objects(Report.self)
        metrics = [MetricBlank]()
        let findReports = reports.where {
            $0.name == reportName && $0.users.nickname == username
        }
        if findReports.count == 1 {
            for metric in findReports.first!.metrics {
                let metricBlank = MetricBlank(name: metric.name, level: metric.level, value: metric.value, maxValue: metric.maxValue)
                metrics.append(metricBlank)
            }
        }
    }
}

//MARK: - Constants

private struct MetricModelConstants {
    
    static let goodTotalResult = 5.0
    static let badTotalResult = 1.5
    static let minimumCoefForMetric = 1
    static let lowCoefForMetric = 2
    static let mediumCoefForMetric = 3
    static let maxCoefForMetric = 4
    static let badWordsAmount = 15
    static let goodWordsAmount = 50
    static let forbiddenSymbols = [" ", ",", ".", "?","!"]
    //possible rating of the app from worst to best
    static let ratings = [1,2,3,4,5]
    //possible rating coeficient from worst to best
    static let ratingCoefs = [1, 0.8, 0.6, 0.2, 0]
    //possible review length coeficient from worst to best
    static let longCoefs = [0.25, 0.5, 1]
    //Vocabulary based on book "War and Peace" on 3 languages: ukrainian, english and russian
    static let vocabulary = ["yl": 87, "on": 1267, "вз": 267, "гр": 506, "ые": 92, "хє": 1, "ey": 173, "yy": 10, "ек": 450, "жб": 26, "кк": 54, "оp": 2, "їц": 5, "ам": 1350, "зo": 1, "uс": 2, "єд": 37, "нq": 1, "аo": 1, "їк": 48, "нц": 209, "сш": 7, "éj": 9, "ml": 50, "ьб": 123, "yn": 17, "хi": 1, "см": 387, "ью": 37, "тм": 45, "їш": 9, "фн": 9, "lj": 4, "mg": 6, "чн": 173, "nt": 1192, "ve": 573, "óд": 1, "їт": 29, "ях": 96, "те": 1318, "еv": 3, "ск": 1191, "sà": 21, "їм": 77, "sv": 54, "юн": 113, "оь": 1, "ох": 306, "sx": 3, "оl": 3, "бц": 7, "yê": 1, "ун": 394, "it": 900, "фу": 26, "lт": 1, "ст": 3012, "op": 137, "лм": 16, "фп": 8, "хи": 130, "нд": 385, "fq": 1, "іu": 1, "ян": 654, "он": 2324, "уш": 241, "вя": 151, "кз": 58, "uà": 1, "тх": 26, "дl": 1, "ус": 922, "rô": 6, "шт": 100, "тi": 1, "sd": 129, "гт": 24, "дс": 146, "йс": 406, "жp": 1, "фя": 2, "cr": 83, "юо": 50, "бc": 2, "ор": 1825, "ху": 123, "rа": 1, "ча": 668, "мv": 4, "гв": 37, "dw": 146, "mk": 2, "ём": 1, "нй": 4, "ob": 86, "сд": 62, "uw": 20, "лs": 1, "нщ": 45, "iп": 6, "ov": 239, "фб": 3, "ві": 2233, "mé": 20, "vn": 102, "яя": 111, "ré": 50, "дф": 8, "йl": 1, "ны": 356, "eв": 21, "àn": 5, "ыd": 1, "йa": 3, "лц": 2, "cè": 2, "дч": 75, "ся": 1446, "юб": 178, "ui": 208, "цв": 8, "la": 506, "лд": 108, "aé": 13, "ât": 1, "вж": 161, "мї": 7, "iy": 1, "ej": 88, "ми": 1381, "сн": 332, "ьc": 2, "юq": 2, "щь": 3, "ên": 4, "пс": 12, "гн": 132, "ér": 28, "юч": 700, "ьи": 97, "яг": 291, "bv": 2, "sn": 110, "нь": 527, "se": 866, "sa": 761, "бщ": 18, "oa": 96, "хs": 2, "éh": 1, "еl": 4, "тд": 51, "уm": 11, "чэ": 1, "аn": 3, "сж": 9, "eq": 99, "fz": 1, "рф": 16, "ur": 499, "ar": 858, "ды": 56, "чc": 1, "cà": 1, "kq": 1, "чф": 1, "ші": 89, "lo": 388, "zz": 1, "іп": 438, "мф": 10, "мт": 98, "ан": 2475, "бж": 2, "ém": 5, "yb": 54, "ns": 392, "тв": 439, "ік": 373, "eб": 12, "te": 1043, "жь": 4, "лe": 1, "йю": 2, "вl": 1, "уб": 214, "зл": 129, "іт": 538, "аа": 204, "sz": 1, "tз": 1, "иà": 3, "sr": 64, "jj": 1, "ée": 34, "eї": 1, "иґ": 1, "уэ": 3, "иг": 381, "яr": 1, "ии": 131, "fw": 124, "tв": 2, "rd": 205, "ra": 656, "dt": 456, "ол": 2017, "òп": 1, "lc": 25, "аx": 7, "uo": 43, "вp": 2, "oр": 1, "кщ": 56, "вб": 151, "nz": 6, "ія": 314, "nо": 2, "ен": 2123, "нп": 203, "яc": 4, "té": 55, "wu": 2, "ою": 684, "cя": 1, "rg": 82, "іл": 707, "оx": 1, "lu": 113, "eд": 5, "hр": 1, "юв": 214, "ёр": 3, "кv": 1, "ыл": 217, "шщ": 7, "ха": 446, "чж": 1, "bi": 62, "гш": 10, "иc": 7, "мж": 20, "юe": 2, "dв": 1, "яt": 1, "ли": 2577, "уе": 35, "гк": 36, "ri": 797, "nл": 1, "жя": 11, "zb": 5, "eя": 12, "ьп": 205, "ці": 358, "rä": 1, "bê": 2, "нб": 98, "дв": 349, "ай": 624, "сб": 28, "sо": 6, "sk": 68, "об": 1798, "яф": 8, "ьj": 1, "mm": 122, "ъя": 8, "tц": 1, "оо": 353, "иі": 171, "яі": 140, "йе": 15, "ьa": 3, "бд": 17, "db": 120, "gu": 88, "ке": 163, "hj": 4, "вє": 3, "ий": 1203, "dq": 10, "yd": 66, "oк": 2, "жз": 12, "мя": 157, "єу": 2, "zt": 4, "оа": 124, "ып": 61, "жї": 1, "лг": 40, "бр": 415, "о́т": 7, "ьm": 8, "нт": 299, "uб": 1, "еф": 11, "оі": 137, "вн": 922, "уо": 102, "ка": 2550, "зю": 34, "vi": 239, "лх": 1, "тг": 22, "ів": 1277, "пб": 1, "hb": 18, "оb": 2, "сы": 63, "иш": 272, "ея": 162, "їа": 16, "юя": 52, "ex": 113, "âm": 4, "és": 24, "vк": 2, "ый": 183, "йg": 1, "óн": 2, "na": 611, "нч": 98, "ач": 547, "хз": 47, "о́г": 4, "àq": 3, "лф": 3, "oé": 3, "sч": 1, "pj": 4, "зу": 424, "тя": 279, "uç": 2, "gv": 10, "ыв": 187, "sн": 2, "sl": 163, "rk": 30, "ла": 2461, "юд": 253, "tk": 19, "бю": 7, "dз": 1, "хг": 48, "иє": 38, "вп": 404, "їґ": 1, "nа": 1, "нн": 1123, "bo": 241, "be": 435, "іц": 177, "fm": 15, "zc": 6, "ix": 13, "бы": 387, "hi": 897, "aw": 117, "in": 1908, "їб": 27, "gц": 1, "iн": 4, "ьф": 8, "kc": 10, "êv": 1, "дх": 31, "rt": 357, "hm": 34, "ры": 160, "bu": 196, "дь": 154, "dp": 204, "ys": 140, "зк": 125, "ёу": 4, "lg": 20, "яu": 2, "ді": 461, "їй": 70, "йt": 2, "гу": 292, "гп": 18, "іі": 117, "ом": 2172, "wt": 49, "ss": 713, "іv": 1, "mt": 120, "wj": 2, "мю": 13, "о̀в": 1, "єв": 46, "йк": 186, "og": 40, "aп": 2, "xv": 12, "вm": 1, "de": 801, "ню": 89, "же": 903, "nи": 3, "ит": 1531, "ho": 518, "тт": 156, "vr": 26, "gm": 46, "нз": 130, "юі": 80, "вї": 58, "кc": 1, "ое": 294, "ud": 79, "вю": 5, "zy": 1, "нє": 16, "tм": 1, "eа": 10, "uг": 1, "иf": 1, "оэ": 37, "év": 12, "чд": 8, "dv": 27, "еш": 193, "щу": 15, "па́": 1, "рм": 146, "mp": 157, "бт": 20, "кй": 5, "пз": 1, "хц": 8, "вр": 250, "юx": 1, "яd": 1, "оъ": 1, "sц": 1, "бл": 460, "єж": 5, "ює": 12, "бe": 1, "рч": 25, "ac": 401, "wm": 15, "gy": 8, "wv": 2, "aз": 1, "чт": 423, "hc": 21, "df": 67, "gc": 6, "zn": 4, "bd": 1, "шй": 1, "lк": 1, "юе": 17, "сі": 414, "йб": 171, "еà": 1, "фы": 4, "èc": 2, "ёг": 3, "în": 3, "àл": 1, "ої": 472, "чб": 21, "xp": 70, "нх": 25, "uy": 2, "шc": 1, "юm": 1, "kb": 7, "хэ": 6, "ça": 11, "ыа": 5, "аq": 1, "xк": 3, "os": 296, "пк": 24, "wp": 5, "си": 662, "if": 146, "nd": 1339, "їв": 120, "oî": 1, "aq": 11, "sb": 133, "зя": 243, "юї": 5, "йщ": 23, "ön": 1, "ги": 285, "сх": 69, "сё": 78, "aк": 1, "ad": 454, "ыщ": 1, "tg": 20, "о́о": 7, "id": 378, "ты": 191, "зв": 438, "nx": 4, "ґв": 1, "aa": 23, "fb": 8, "lm": 55, "ье": 232, "my": 95, "ид": 767, "зі": 187, "яи": 96, "рь": 113, "ph": 23, "ыг": 27, "mo": 433, "зы": 61, "zi": 12, "ат": 1998, "щн": 3, "xc": 41, "oq": 5, "nn": 250, "о́б": 2, "én": 9, "шр": 4, "co": 635, "йэ": 10, "xm": 3, "yf": 51, "ру": 968, "bl": 158, "йу": 75, "лш": 7, "іq": 1, "дд": 45, "кю": 13, "ыш": 65, "ой": 607, "бó": 1, "nm": 58, "ét": 50, "oc": 98, "рэ": 5, "ує": 40, "єч": 1, "nр": 1, "хa": 2, "іn": 1, "аю": 653, "нe": 1, "óо": 1, "rn": 120, "оt": 2, "гє": 3, "hv": 9, "vв": 4, "pi": 235, "пи": 402, "кi": 1, "ым": 200, "цт": 6, "пш": 1, "ъю": 10, "яю": 73, "ёт": 12, "fя": 1, "èl": 1, "яe": 3, "mі": 1, "рг": 100, "єа": 2, "iс": 4, "юц": 29, "йy": 1, "ць": 198, "hy": 48, "яв": 753, "хщ": 14, "хл": 79, "éà": 5, "az": 10, "ык": 54, "dr": 234, "бг": 5, "уw": 1, "уx": 2, "цг": 9, "дя": 173, "éд": 4, "eц": 3, "ма": 1248, "єе": 1, "sт": 1, "yk": 9, "о́у": 1, "en": 1275, "ek": 34, "gс": 1, "sб": 1, "ад": 1037, "çr": 1, "аa": 9, "ви": 2091, "мэ": 8, "dz": 1, "пá": 1, "бà": 1, "ня": 1632, "цм": 6, "зъ": 1, "pw": 8, "іш": 312, "іч": 217, "gb": 28, "гц": 2, "оc": 4, "єб": 7, "тк": 180, "яп": 333, "rд": 1, "мл": 76, "хм": 56, "її": 166, "ès": 30, "км": 54, "яз": 813, "gq": 1, "et": 872, "nb": 50, "ещ": 235, "жу": 162, "eл": 2, "аu": 3, "ио": 360, "чм": 5, "йп": 307, "шл": 185, "хр": 67, "mu": 58, "пм": 1, "pk": 1, "ыэ": 10, "да": 1172, "vo": 314, "тч": 42, "iî": 1, "су": 327, "lс": 1, "xв": 2, "él": 26, "цк": 7, "éн": 1, "pô": 1, "вф": 9, "lè": 9, "rr": 289, "tè": 1, "ьр": 38, "hd": 10, "ie": 569, "їя": 11, "зг": 161, "ng": 991, "юф": 10, "lг": 1, "ht": 214, "uc": 114, "rf": 93, "еь": 1, "nj": 14, "тй": 2, "ap": 277, "dg": 49, "ії": 110, "tп": 3, "эй": 2, "lп": 3, "sп": 10, "тн": 289, "яб": 162, "yu": 7, "чщ": 1, "не": 2881, "бs": 1, "аґ": 3, "лр": 17, "nr": 34, "fo": 273, "ёд": 1, "pd": 6, "о́н": 1, "хч": 23, "hс": 3, "иу": 106, "sm": 192, "тò": 8, "éп": 1, "vt": 3, "їн": 52, "кє": 1, "da": 415, "pl": 171, "па̀": 1, "uh": 26, "зn": 1, "тx": 1, "pb": 9, "ао": 328, "oц": 2, "zm": 8, "fê": 1, "фм": 2, "юl": 1, "xи": 1, "хт": 97, "èt": 1, "чп": 14, "ku": 11, "бі": 447, "ґу": 3, "юc": 7, "ей": 568, "эл": 4, "lw": 41, "нb": 1, "шм": 12, "nê": 2, "пв": 1, "ip": 74, "ни": 2058, "яд": 478, "юш": 18, "là": 12, "жі": 91, "rs": 419, "оv": 5, "pa": 366, "yw": 75, "дм": 93, "vs": 17, "юи": 48, "ду": 696, "ll": 643, "ya": 236, "се": 848, "фв": 12, "уч": 342, "ls": 93, "иi": 5, "lh": 44, "мu": 1, "йї": 5, "гс": 37, "пю": 3, "їщ": 10, "вà": 1, "èr": 85, "dc": 51, "ln": 32, "xd": 7, "fn": 7, "еi": 1, "эг": 5, "pv": 1, "lk": 47, "йє": 5, "нс": 222, "ас": 1842, "юм": 83, "tê": 11, "fc": 26, "ьа": 189, "йз": 147, "рл": 47, "ьм": 172, "gi": 152, "жй": 1, "ьо": 540, "éи": 1, "мj": 1, "уc": 4, "ws": 45, "ôl": 4, "тє": 5, "fl": 46, "ет": 943, "oh": 117, "жи": 286, "cé": 6, "юn": 2, "xg": 1, "vа": 1, "цы": 12, "ел": 1127, "еэ": 21, "яр": 86, "sи": 1, "лa": 2, "рж": 72, "by": 71, "ша": 321, "аэ": 37, "es": 1537, "su": 208, "yв": 1, "шв": 49, "лн": 95, "no": 632, "аз": 1649, "ég": 6, "иn": 3, "ае": 202, "xo": 2, "ed": 1241, "гл": 506, "рш": 124, "ög": 1, "od": 115, "пы": 18, "мр": 71, "eм": 6, "яо": 129, "ту": 649, "ih": 38, "іc": 5, "ул": 790, "ош": 263, "sf": 134, "ыр": 56, "tq": 47, "ід": 1183, "еї": 93, "йо": 662, "мe": 1, "ös": 1, "éa": 9, "пн": 24, "ґе": 1, "ят": 583, "дї": 37, "ro": 547, "óх": 2, "vé": 7, "оц": 138, "зр": 187, "хо": 926, "фз": 9, "rx": 11, "ех": 173, "кх": 16, "ny": 88, "ks": 32, "gn": 49, "дз": 52, "ьт": 144, "va": 123, "ьf": 1, "вщ": 99, "iд": 1, "чш": 13, "ук": 571, "eс": 47, "йж": 44, "bé": 3, "ww": 18, "ре": 1462, "йй": 8, "as": 903, "ok": 152, "cl": 84, "цс": 9, "èn": 2, "юю": 40, "пі": 512, "юж": 26, "hp": 23, "мк": 158, "рр": 26, "tô": 1, "сй": 3, "wg": 2, "he": 2574, "ъе": 12, "аш": 394, "rq": 24, "âc": 7, "òс": 1, "mh": 36, "rh": 120, "ок": 1023, "gg": 23, "ёе": 3, "жщ": 1, "жж": 1, "óя": 2, "iі": 2, "um": 94, "ja": 32, "rç": 1, "zh": 2, "ly": 385, "йґ": 2, "óг": 1, "bt": 3, "шп": 28, "bn": 3, "кі": 512, "дг": 35, "fu": 83, "ыж": 12, "dn": 129, "уі": 118, "сї": 7, "бх": 17, "mw": 29, "ип": 826, "pè": 21, "жв": 38, "ео": 293, "yr": 35, "ak": 110, "ге": 157, "xh": 1, "ше": 552, "ін": 1414, "mê": 3, "іх": 269, "râ": 6, "хв": 216, "wn": 80, "зм": 191, "аj": 4, "vс": 1, "хv": 1, "tи": 1, "ёэ": 7, "eш": 5, "ue": 296, "гб": 8, "бп": 16, "sі": 1, "ыч": 21, "дл": 207, "vп": 1, "еп": 791, "ub": 35, "ют": 222, "мп": 246, "ув": 1313, "rê": 9, "zr": 2, "нl": 1, "сс": 140, "шn": 1, "ив": 2191, "йд": 249, "üs": 1, "éb": 2, "il": 524, "фр": 140, "яj": 5, "нг": 93, "вa": 2, "du": 116, "мq": 2, "жн": 432, "мс": 252, "lв": 2, "eі": 10, "xa": 22, "дк": 166, "us": 614, "ая": 541, "eх": 2, "єй": 7, "їф": 2, "xl": 1, "ûl": 3, "вс": 1385, "яq": 2, "kd": 6, "uп": 4, "tд": 2, "мч": 93, "иm": 15, "іl": 2, "йц": 37, "мa": 1, "lâ": 4, "кс": 158, "шш": 1, "ld": 197, "іф": 16, "ых": 97, "pf": 5, "éq": 3, "дю": 44, "vg": 1, "iv": 128, "еt": 2, "hk": 2, "иp": 4, "om": 546, "лю": 403, "чз": 16, "vè": 1, "оя": 378, "яэ": 16, "iв": 5, "жх": 10, "iя": 1, "àp": 5, "ци": 68, "hl": 7, "єя": 6, "шг": 4, "вu": 2, "ei": 345, "ёз": 3, "un": 475, "np": 94, "кв": 218, "hq": 3, "im": 362, "cg": 1, "о́е": 2, "ыс": 103, "єі": 13, "са": 462, "о́с": 2, "иб": 356, "ащ": 164, "жд": 160, "вч": 160, "wr": 20, "уя": 108, "do": 390, "oв": 2, "хж": 15, "éd": 13, "ау": 142, "ьв": 329, "hw": 31, "за": 2276, "іб": 228, "иd": 3, "yv": 8, "лв": 67, "пя": 81, "òд": 1, "бу": 1008, "ec": 580, "ch": 525, "ct": 138, "jч": 1, "ощ": 171, "ши": 742, "фк": 11, "ga": 234, "io": 251, "fг": 1, "rà": 6, "кт": 153, "іa": 1, "zq": 9, "о́l": 1, "аи": 177, "sh": 570, "éi": 1, "sê": 8, "аф": 285, "àc": 7, "xп": 3, "xà": 3, "ыз": 24, "ut": 458, "cc": 24, "ià": 1, "ce": 861, "fу": 1, "ря": 283, "чг": 4, "wh": 404, "ыя": 7, "cf": 3, "іи": 3, "юх": 27, "ср": 37, "nh": 153, "бй": 6, "йв": 219, "rк": 5, "лч": 62, "ay": 208, "од": 1842, "иa": 3, "шд": 8, "єш": 42, "ab": 192, "dé": 46, "мm": 6, "ky": 7, "кп": 97, "jà": 7, "зд": 313, "ще": 299, "чу": 294, "цc": 1, "о́ж": 3, "ci": 128, "лт": 34, "sq": 51, "tn": 57, "lд": 1, "аé": 1, "iб": 1, "жл": 39, "кф": 3, "ьї": 17, "яf": 1, "юd": 3, "уi": 1, "kn": 99, "кї": 2, "vу": 2, "фл": 21, "рс": 142, "lé": 15, "ьє": 12, "чс": 13, "yя": 1, "ge": 246, "яц": 49, "жч": 49, "фг": 1, "вэ": 25, "єл": 5, "бс": 33, "їр": 30, "tp": 100, "mi": 353, "le": 961, "ва": 2376, "сч": 37, "шн": 148, "нм": 42, "eз": 8, "ck": 84, "av": 273, "зl": 3, "oo": 330, "єc": 3, "єu": 1, "èg": 2, "ko": 34, "уl": 1, "нф": 3, "sа": 1, "тп": 95, "wl": 10, "óс": 1, "nç": 5, "nc": 500, "іг": 229, "о́и": 1, "fs": 23, "вд": 370, "au": 217, "rш": 1, "нш": 96, "хк": 51, "юг": 42, "кл": 213, "о̀л": 1, "yé": 2, "мн": 550, "шо": 287, "оi": 3, "то́": 69, "сп": 660, "оm": 12, "ыa": 2, "вй": 84, "іе": 29, "еx": 1, "щи": 90, "яй": 88, "еu": 2, "сз": 25, "со": 690, "мь": 3, "аe": 3, "оє": 125, "ti": 731, "ьж": 16, "eт": 11, "чь": 18, "уг": 378, "óк": 3, "dd": 117, "ээ": 1, "яу": 58, "хд": 62, "kr": 3, "еz": 1, "cq": 9, "иж": 134, "ua": 85, "чю": 6, "fа": 1, "ар": 1283, "чя": 118, "hs": 43, "lt": 118, "ca": 254, "yp": 32, "tà": 24, "бб": 16, "hg": 5, "ym": 35, "nп": 3, "zp": 16, "лж": 40, "оj": 3, "sp": 255, "rс": 7, "аб": 556, "ёя": 1, "àm": 12, "кц": 20, "gм": 2, "їл": 19, "fe": 163, "ух": 224, "зб": 109, "их": 779, "ыу": 12, "pê": 3, "ki": 134, "пу": 210, "єр": 193, "yç": 1, "ее": 212, "ед": 844, "ьн": 520, "mf": 10, "зе": 86, "pr": 442, "ть": 1275, "єх": 1, "uq": 8, "чх": 4, "ьу": 84, "êm": 7, "ux": 23, "іу": 45, "or": 677, "br": 75, "цп": 5, "oi": 249, "че": 820, "eк": 15, "vг": 3, "хm": 3, "эк": 4, "àt": 3, "ьз": 127, "ae": 12, "rт": 3, "vy": 1, "їу": 9, "о́в": 4, "sg": 46, "gè": 1, "we": 276, "лб": 33, "tх": 2, "пл": 294, "eг": 8, "nl": 119, "eу": 2, "ёо": 4, "еg": 1, "ьэ": 24, "ож": 542, "dh": 267, "св": 634, "пр": 1987, "цб": 1, "so": 536, "кн": 1042, "лі": 582, "єф": 2, "gl": 105, "gé": 6, "fi": 177, "at": 1056, "ug": 143, "uv": 80, "ву": 496, "sв": 5, "nт": 2, "ин": 1979, "кl": 2, "sу": 3, "uj": 12, "еb": 3, "eн": 8, "iк": 4, "кд": 64, "о́п": 1, "нр": 44, "aі": 1, "ог": 2462, "ke": 179, "fa": 267, "vj": 2, "тc": 1, "йт": 255, "о́з": 2, "né": 17, "êc": 2, "иф": 29, "жк": 86, "сl": 2, "ka": 42, "fv": 3, "ai": 625, "гї": 3, "lr": 28, "ьl": 1, "ає": 211, "иx": 4, "чр": 5, "cu": 60, "мі": 904, "гф": 3, "бш": 3, "wc": 5, "ум": 541, "ba": 93, "о̀г": 1, "rû": 1, "çu": 4, "kп": 1, "ьй": 34, "зч": 35, "rч": 1, "еe": 4, "дй": 6, "дъ": 12, "юп": 137, "wq": 2, "rl": 145, "yh": 74, "gh": 293, "gs": 74, "бэ": 4, "hu": 54, "пэ": 1, "tl": 234, "rv": 73, "де": 937, "ne": 787, "рє": 16, "iu": 4, "чл": 20, "вт": 303, "сщ": 3, "ьк": 882, "bc": 1, "ef": 251, "еd": 1, "tv": 33, "бо": 773, "мl": 4, "уж": 468, "fd": 9, "eg": 181, "лз": 16, "оч": 889, "nз": 1, "kw": 15, "dk": 16, "ве": 1134, "ущ": 118, "йя": 56, "lv": 26, "бь": 5, "pq": 1, "нж": 6, "pe": 455, "зт": 102, "пц": 6, "zo": 3, "uf": 20, "єо": 9, "hè": 46, "nu": 60, "fé": 2, "кэ": 10, "гі": 113, "тj": 1, "єa": 1, "nw": 94, "ею": 96, "lp": 36, "ea": 1052, "уф": 20, "ez": 142, "ыи": 51, "мd": 1, "сэ": 5, "af": 110, "xw": 1, "tк": 5, "yj": 3, "zs": 2, "дэ": 2, "ья": 131, "nь": 1, "вк": 307, "о̀з": 1, "шб": 10, "шя": 6, "єк": 9, "пп": 30, "іо": 164, "nv": 68, "aд": 1, "йv": 1, "кx": 1, "яє": 17, "bâ": 6, "mè": 8, "tн": 4, "шс": 23, "гщ": 2, "уt": 2, "ff": 94, "яа": 123, "to": 1050, "ye": 129, "зс": 136, "àa": 2, "wi": 457, "xj": 1, "фо": 40, "lі": 2, "зщ": 6, "фе": 43, "zu": 13, "оe": 1, "vw": 6, "ze": 21, "ір": 278, "óж": 1, "ir": 310, "йф": 11, "юa": 1, "wk": 6, "sя": 4, "чк": 168, "ib": 68, "ыx": 1, "юй": 13, "гя": 4, "иb": 1, "iр": 3, "яш": 26, "ah": 65, "fh": 72, "гй": 2, "зь": 491, "àé": 2, "дц": 66, "нx": 1, "йх": 25, "мш": 16, "rp": 74, "iz": 15, "éб": 1, "hn": 13, "òт": 1, "km": 9, "рj": 1, "aч": 1, "їг": 22, "tr": 349, "дш": 40, "бъ": 6, "eф": 1, "зш": 12, "хс": 89, "ew": 397, "тї": 6, "el": 639, "иv": 3, "уq": 1, "kp": 4, "ьл": 48, "йч": 110, "то": 2719, "ik": 108, "еj": 2, "mг": 1, "зп": 193, "мц": 29, "гp": 1, "ко": 2551, "wd": 15, "hö": 2, "жц": 4, "éc": 24, "éu": 3, "fr": 163, "та": 2213, "иl": 6, "gt": 147, "це": 551, "сл": 593, "кж": 22, "ъв": 1, "vl": 49, "lq": 4, "zj": 2, "ґі": 1, "вы": 333, "бї": 2, "о̀т": 1, "йр": 97, "им": 1428, "je": 141, "юу": 46, "жт": 20, "кa": 1, "йа": 57, "sé": 21, "cy": 11, "нв": 125, "ра": 2540, "àà": 2, "nс": 10, "бм": 26, "чї": 3, "rу": 1, "еб": 683, "ij": 12, "xt": 26, "хб": 65, "uz": 9, "td": 116, "vh": 4, "пp": 1, "рз": 69, "ёв": 6, "аi": 8, "щд": 1, "vc": 2, "зо": 294, "ич": 615, "ег": 554, "àl": 28, "lf": 103, "шк": 166, "di": 471, "fp": 17, "аm": 20, "иї": 128, "mв": 1, "пч": 9, "ои": 220, "ёи": 3, "би": 435, "яs": 2, "mr": 5, "фд": 6, "àс": 1, "ao": 9, "єм": 92, "py": 8, "ез": 786, "wb": 6, "пє": 172, "ué": 4, "чй": 1, "sщ": 1, "фи": 145, "гд": 137, "рп": 73, "xq": 4, "зж": 45, "еч": 348, "іm": 8, "эд": 2, "о̀д": 2, "зи": 162, "xг": 1, "їс": 53, "хя": 23, "ьч": 101, "шц": 8, "sэ": 1, "лу": 435, "rз": 1, "сє": 1, "нк": 205, "ыд": 32, "юс": 177, "gk": 1, "фі": 105, "xs": 2, "фї": 1, "vu": 1, "eh": 338, "рб": 92, "мд": 112, "зз": 86, "йл": 138, "aи": 2, "вq": 1, "gr": 134, "êt": 35, "дт": 70, "ак": 1500, "aс": 3, "ля": 949, "бв": 32, "во": 2599, "рm": 1, "сг": 17, "аж": 470, "sд": 3, "єю": 55, "ль": 974, "зн": 807, "rп": 7, "бф": 1, "rc": 121, "яї": 27, "бb": 1, "уї": 12, "ïs": 1, "йc": 1, "ющ": 87, "tт": 1, "ot": 530, "ал": 2635, "ію": 105, "éз": 2, "еж": 292, "nq": 24, "zà": 1, "ds": 292, "мы": 67, "лt": 2, "ур": 342, "éf": 1, "тu": 1, "оз": 1004, "тъ": 2, "em": 484, "zd": 13, "їч": 9, "эр": 1, "еm": 7, "ён": 4, "eщ": 3, "rb": 65, "эс": 1, "me": 717, "ii": 40, "хп": 100, "шз": 5, "уb": 3, "бч": 17, "sc": 203, "тф": 16, "ёк": 2, "ms": 83, "zé": 1, "сц": 49, "li": 480, "лэ": 7, "цх": 1, "oz": 2, "яa": 4, "fy": 19, "вш": 409, "zv": 17, "ын": 111, "от": 1563, "às": 2, "xy": 3, "dl": 106, "тó": 25, "дщ": 7, "eà": 12, "лп": 90, "шї": 2, "жо": 33, "рщ": 19, "уp": 2, "tе": 1, "нэ": 7, "сь": 1309, "óе": 3, "фф": 2, "съ": 1, "оs": 1, "nв": 3, "mз": 2, "уп": 496, "фэ": 1, "rо": 4, "иt": 1, "dè": 2, "іx": 4, "tі": 2, "вc": 1, "кб": 137, "то̀": 3, "éс": 6, "àd": 3, "тр": 957, "ди": 1184, "óв": 1, "cv": 2, "мщ": 40, "рю": 65, "сe": 1, "th": 2419, "мв": 213, "єє": 2, "яч": 232, "єн": 33, "cк": 1, "аc": 8, "dî": 1, "yi": 112, "мо": 1453, "шф": 1, "оґ": 2, "уa": 15, "сm": 3, "tb": 91, "cm": 1, "ni": 298, "uk": 24, "рн": 369, "ic": 364, "аl": 4, "er": 1925, "ес": 1098, "gf": 26, "ґа": 11, "цл": 5, "iq": 23, "нa": 1, "gp": 28, "ît": 4, "ôt": 5, "ep": 446, "aî": 5, "eи": 11, "àв": 1, "га": 605, "ац": 130, "еa": 5, "въ": 3, "kt": 23, "am": 372, "mc": 11, "is": 1050, "тс": 183, "йн": 357, "ле": 1040, "иа": 129, "нc": 2, "hh": 75, "лp": 1, "їю": 2, "bb": 14, "рй": 8, "ry": 212, "шa": 1, "mb": 59, "о́д": 1, "sг": 3, "чі": 174, "го": 3138, "sw": 190, "kh": 101, "чв": 12, "чч": 156, "ящ": 77, "аb": 2, "yд": 1, "юз": 87, "sс": 8, "еа": 87, "іщ": 113, "vо": 1, "жс": 29, "єц": 9, "ов": 3962, "an": 1921, "ts": 317, "qu": 305, "wf": 16, "хі": 114, "ім": 394, "їо": 22, "pc": 3, "ищ": 219, "tç": 2, "ут": 621, "ьд": 118, "ер": 2388, "ig": 163, "эн": 6, "vm": 2, "éг": 1, "тm": 1, "зї": 11, "eb": 200, "тю": 53, "lb": 30, "ца": 87, "рк": 138, "лы": 142, "uu": 5, "єс": 12, "яv": 1, "зф": 8, "но": 2507, "їm": 2, "cp": 2, "йш": 221, "cd": 6, "рд": 125, "ба": 711, "ia": 141, "мм": 72, "іd": 1, "lе": 2, "dê": 3, "ап": 1057, "ft": 209, "аг": 579, "ия": 325, "òв": 1, "ев": 908, "вг": 168, "вц": 63, "дб": 57, "ol": 271, "жп": 17, "еі": 71, "ьщ": 38, "ou": 1410, "fk": 4, "lа": 1, "вt": 1, "до": 1689, "яl": 3, "iт": 1, "ие": 308, "ща": 139, "оф": 168, "za": 7, "ёс": 5, "уу": 42, "йі": 90, "ёп": 7, "rm": 154, "ji": 1, "ил": 1421, "dm": 92, "zl": 11, "zс": 2, "лс": 218, "gj": 4, "иo": 1, "ло": 2092, "па": 570, "ьx": 2, "mн": 1, "nм": 1, "ma": 563, "фт": 7, "щі": 22, "оn": 1, "ир": 484, "ну": 1165, "жм": 23, "шь": 54, "аv": 3, "хф": 5, "тб": 42, "тш": 7, "ié": 14, "nâ": 1, "óи": 1, "оa": 2, "нf": 1, "йг": 115, "kg": 3, "ps": 36, "àe": 4, "єз": 14, "мх": 34, "ию": 32, "jç": 1, "eп": 14, "пт": 56, "eu": 246, "іo": 1, "цн": 22, "rі": 3, "тз": 44, "яж": 243, "dy": 95, "ти": 2067, "xx": 9, "йм": 175, "сю": 60, "cs": 13, "зх": 14, "wo": 158, "ті": 668, "нj": 1, "бє": 5, "tf": 70, "хн": 162, "жг": 8, "чо": 318, "дп": 165, "iè": 10, "ем": 977, "бк": 53, "aj": 7, "шч": 7, "dj": 13, "gd": 16, "бз": 11, "єп": 24, "вь": 15, "èv": 3, "ào": 1, "кm": 5, "иy": 2, "їp": 1, "лл": 29, "іс": 714, "жр": 7, "кш": 14, "éo": 1, "кч": 26, "рl": 2, "ис": 1800, "що": 1005, "рв": 137, "kö": 1, "хш": 8, "нi": 2, "уц": 55, "хc": 1, "жф": 1, "уe": 3, "уv": 5, "єт": 110, "tw": 168, "вy": 1, "ôn": 2, "iw": 35, "о́м": 7, "иц": 333, "ty": 127, "wy": 14, "eé": 1, "eо": 6, "yo": 390, "пь": 134, "tt": 540, "тл": 60, "нї": 3, "юк": 95, "иj": 2, "гм": 14, "ця": 134, "вл": 408, "рх": 52, "эм": 2, "чц": 3, "ец": 157, "pm": 6, "nà": 3, "дz": 1, "юр": 91, "йs": 1, "йи": 64, "eç": 8, "йd": 1, "ку": 860, "ні": 1263, "мг": 93, "рі": 826, "ёх": 2, "wa": 529, "яn": 1, "юэ": 1, "éі": 1, "гх": 1, "tc": 125, "бя": 63, "ыб": 108, "ta": 549, "лщ": 2, "ьс": 484, "жє": 1, "hé": 15, "ьг": 63, "re": 1609, "еc": 6, "вх": 47, "oj": 6, "зm": 3, "цу": 127, "сo": 1, "из": 661, "rè": 27, "лй": 1, "xu": 1, "жю": 19, "чm": 2, "эз": 2, "nі": 1, "mv": 6, "sм": 4, "nя": 1, "оу": 96, "nk": 54, "ha": 1024, "дж": 98, "ял": 301, "ul": 241, "їп": 53, "гг": 9, "йm": 3, "зa": 2, "ёч": 10, "yq": 1, "вj": 1, "на": 4249, "ьц": 49, "му": 931, "uе": 1, "md": 7, "цю": 76, "tл": 1, "уа": 84, "tâ": 1, "еs": 2, "eч": 2, "al": 583, "ru": 111, "юл": 54, "ям": 303, "щр": 1, "лк": 311, "о̀р": 1, "ьe": 1, "шу": 126, "of": 545, "ow": 418, "kf": 7, "аf": 1, "тщ": 8, "щж": 1, "àr": 2, "po": 271, "àv": 6, "сф": 8, "вd": 2, "гэ": 4, "xe": 20, "тж": 24, "ро": 2721, "eo": 265, "уj": 2, "хх": 9, "зц": 19, "ьш": 134, "яm": 7, "уи": 71, "ax": 4, "дн": 740, "їз": 69, "иq": 1, "zf": 2, "жа": 443, "рv": 2, "зє": 7, "цд": 3, "ju": 54, "tс": 3, "мc": 2, "шm": 1, "oy": 86, "еу": 94, "лc": 1, "pé": 25, "ри": 1780, "ах": 436, "hr": 66, "go": 173, "ьх": 31, "мз": 164, "aл": 1, "хе": 17, "fс": 1, "rw": 83, "ую": 283, "bj": 5, "кр": 571, "вe": 7, "уз": 380, "аї": 77, "àf": 2, "рц": 55, "юа": 49, "іж": 119, "хї": 7, "фс": 8, "аp": 3, "yg": 22, "іє": 126, "tz": 3, "ій": 748, "уo": 1, "бе": 537, "xi": 26, "вв": 361, "éт": 3, "мє": 1, "eэ": 2, "гз": 30, "мй": 9, "хй": 6, "мб": 83, "еи": 127, "пе": 825, "nн": 1, "нл": 19, "tu": 196, "uк": 1, "по": 2888, "ыо": 37, "ыт": 71, "др": 679, "ёа": 2, "yt": 165, "hf": 12, "аs": 3, "ag": 190, "ev": 408, "тэ": 14, "eр": 5, "lz": 2, "їж": 50, "mn": 11, "pt": 76, "їі": 46, "єщ": 13, "уд": 678, "lу": 2, "єг": 5, "іа": 81, "аі": 180, "rм": 1, "бн": 102, "bh": 1, "sк": 3, "фа": 85, "jo": 43, "кя": 38, "иэ": 25, "up": 135, "ьà": 2, "rв": 6, "яе": 51, "цо": 86, "nf": 77, "жэ": 1, "oe": 49, "уй": 98, "ав": 2938, "ьі": 120, "єї": 69, "rj": 6, "ме": 725, "їх": 212, "sy": 58, "ee": 430, "їд": 86, "eж": 1, "éк": 1, "гч": 6, "рї": 3, "êl": 2, "bs": 15, "ик": 925, "із": 493, "зй": 5, "эт": 219, "кг": 36, "оп": 996, "яp": 1, "kl": 15, "pp": 106, "rи": 2, "gw": 49, "ёб": 6, "тц": 37, "pu": 61, "sj": 23, "éя": 2, "jh": 1, "еє": 7, "еp": 2, "fк": 2, "àu": 5, "як": 1127, "вм": 146, "чи": 1323, "si": 660, "зэ": 5, "ки": 1262, "лє": 1, "yc": 29, "ос": 2355, "st": 951, "ép": 19, "tj": 20, "fg": 7, "tщ": 1, "tm": 102, "яс": 372, "рт": 283, "о̀б": 1]
    
    //metrics with no values in order
    static func getStartMetrics() -> [MetricBlank] {
        let b5metrics = [MetricBlank(name: "M1b5", coeficient: lowCoefForMetric, level: 5), MetricBlank(name: "M2b5", coeficient: maxCoefForMetric, level: 5), MetricBlank(name: "M1_2b5", coeficient: maxCoefForMetric, level: 5), MetricBlank(name: "M3b5", coeficient: maxCoefForMetric, level: 5), MetricBlank(name: "M4b5", coeficient: maxCoefForMetric, level: 5), MetricBlank(name: "M3_4b5", coeficient: maxCoefForMetric, level: 5), MetricBlank(name: "M5b5", coeficient: lowCoefForMetric, level: 5), MetricBlank(name: "M6b5", coeficient: maxCoefForMetric, level: 5), MetricBlank(name: "M5_6b5", coeficient: maxCoefForMetric, level: 5), MetricBlank(name: "M7b5", coeficient: maxCoefForMetric, level: 5), MetricBlank(name: "M8b5", coeficient: lowCoefForMetric, level: 5), MetricBlank(name: "M7_8b5", coeficient: maxCoefForMetric, level: 5), MetricBlank(name: "M9b5", coeficient: mediumCoefForMetric, level: 5), MetricBlank(name: "M10b5", coeficient: maxCoefForMetric, level: 5), MetricBlank(name: "M9_10b5", coeficient: maxCoefForMetric, level: 5), MetricBlank(name: "M11b5", coeficient: lowCoefForMetric, level: 5), MetricBlank(name: "M12b5", coeficient: maxCoefForMetric, level: 5), MetricBlank(name: "M11_12b5", coeficient: maxCoefForMetric, level: 5), MetricBlank(name: "M13b5", coeficient: lowCoefForMetric, level: 5), MetricBlank(name: "M14b5", coeficient: lowCoefForMetric, level: 5), MetricBlank(name: "M13_14b5", coeficient: lowCoefForMetric, level: 5), MetricBlank(name: "M15b5", coeficient: mediumCoefForMetric, level: 5), MetricBlank(name: "M16b5", coeficient: mediumCoefForMetric, level: 5), MetricBlank(name: "M15_16b5", coeficient: mediumCoefForMetric, level: 5)]
        let d4metrics = [MetricBlank(name: "M1d4", coeficient: maxCoefForMetric, level: 4, childs: b5metrics.filter({$0.name == "M1b5" || $0.name == "M2b5" || $0.name == "M1_2b5"})), MetricBlank(name: "M2d4", coeficient: maxCoefForMetric, level: 4, childs: b5metrics.filter({$0.name == "M3b5" || $0.name == "M4b5" || $0.name == "M3_4b5"})), MetricBlank(name: "M3d4", coeficient: mediumCoefForMetric, level: 4, childs: b5metrics.filter({$0.name == "M5b5" || $0.name == "M6b5" || $0.name == "M5_6b5"})), MetricBlank(name: "M4d4", coeficient: mediumCoefForMetric, level: 4, childs: b5metrics.filter({$0.name == "M7b5" || $0.name == "M8b5" || $0.name == "M7_8b5"})), MetricBlank(name: "M5d4", coeficient: lowCoefForMetric, level: 4, childs: b5metrics.filter({$0.name == "M9b5" || $0.name == "M10b5" || $0.name == "M9_10b5"})), MetricBlank(name: "M6d4", coeficient: lowCoefForMetric, level: 4, childs: b5metrics.filter({$0.name == "M11b5" || $0.name == "M12b5" || $0.name == "M11_12b5"})), MetricBlank(name: "M7d4", coeficient: lowCoefForMetric, level: 4, childs: b5metrics.filter({$0.name == "M13b5" || $0.name == "M14b5" || $0.name == "M13_14b5"})), MetricBlank(name: "M8d4", coeficient: maxCoefForMetric, level: 4, childs: b5metrics.filter({$0.name == "M15b5" || $0.name == "M16b5" || $0.name == "M15_16b5"}))]
        let d3metrics = [MetricBlank(name: "M1d3", coeficient: maxCoefForMetric, level: 3, childs: d4metrics.filter({$0.name == "M1d4" || $0.name == "M2d4"})), MetricBlank(name: "M2d3", coeficient: mediumCoefForMetric, level: 3, childs: d4metrics.filter({$0.name == "M3d4" || $0.name == "M4d4"})), MetricBlank(name: "M3d3", coeficient: lowCoefForMetric, level: 3, childs: d4metrics.filter({$0.name == "M5d4" || $0.name == "M6d4"})), MetricBlank(name: "M4d3", coeficient: minimumCoefForMetric, level: 3, childs: d4metrics.filter({$0.name == "M7d4" || $0.name == "M8d4"}))]
        let d2metrics = [MetricBlank(name: "M1d2", coeficient: maxCoefForMetric, level: 2, number: 1, childs: d3metrics.filter({$0.name == "M1d3" || $0.name == "M2d3"})), MetricBlank(name: "M2d2", coeficient: mediumCoefForMetric, level: 2, number: 2, childs: d3metrics.filter({$0.name == "M1d3" || $0.name == "M2d3"})), MetricBlank(name: "M3d2", coeficient: lowCoefForMetric, level: 2, number: 3, childs: d3metrics.filter({$0.name == "M3d3" || $0.name == "M4d3"})), MetricBlank(name: "M4d2", coeficient: minimumCoefForMetric, level: 2, number: 4, childs: d3metrics.filter({$0.name == "M3d3" || $0.name == "M4d3"}))]
        let d1metric = [MetricBlank(name: "M1d1", coeficient: 0, level: 1, childs: d2metrics)]
        let allMetrics = b5metrics + d4metrics + d3metrics + d2metrics + d1metric
        return allMetrics
    }
    
}


