//
//  Reviews.swift
//  AppQualityAnalysis
//
//  Created by Vlad Nechiporenko on 02.11.2021.
//

import Foundation
import RealmSwift

class Reviews{
    var fullReviews = [[String:Any]]()
    var reviews = [Review]()
    let realm = try! Realm()
    lazy var realmReviews = realm.objects(RealmReview.self)
    var currentReviews = [RealmReview]()
    var words = [String:Int]()
    var reviewsByCategories = [String:[Review]]()
    var M1b5KeyWords = ["ios", "операционая система", "операційна система", " ос ", "operation system", " os "]
    var M2b5KeyWords = ["device", "пристрій", "iphone", "ipad", "устройство", "смартфон", "телефон", "планшет", "мобильный"]
    var M1_2b5KeyWords = ["выбрасыва", "правильн", "работа", "существу", "подтягива", "мог", "выбива", "ошибк", "лаг", "баг", "викида", "працю", "існу", "підтяг", "міг", "вибива", "помилк", "змоги", "можу", "throw", "correct", "work", "exist", "get", "can", "exit", "error", "lag", "bug", "correct"]
    var M4b5KeyWords = ["привязаны", "другие приложения", "tied", "other apps", "прив'язані", "інші застосунки", "через фейсбук", "via"]
    var M3b5KeyWords = ["открыва", "удали", "вход", "убрать", "скача", "настрои", "зайти", "приход", "пропал", "доступ", "видно", "выход", "войти", "выйти", "загруз", "обновить", "зайти", "уведомления", "open", "delete", "enter", "remove", "download", "configure", "disappeared", "access", "visible", "exit", "update", "notifications", "відкрива", "видал", "вхід", "прибрати", "налашту", "пропав", "вихід", "увійти", "вийти", "завантаж", "оновити", "повідомлення"]
    var M5b5KeyWords = ["горизонта", "вертикаль", "дисплей", "ориентация","horizontal", "vertical", "display", "orientation", "орієнтація", "экран", "екран", "screen"]
    var M5_6b5KeyWords = ["меняется", "размер интерфейс", "элементы","змінюється", "розмір інтерфейс", "елементи", "changes", "interface size"]
    var M7b5KeyWords = ["правильн", "належн", "correct"]
    var M8b5KeyWords = ["страшн", "реклама", "ужас", "анимаци", "морга", "пуст", "удобн", "кончен", "плохо", "рыгать", "помойка", "дизайн", "шрифт", "комфорт", "понятн", "бесполезн", "архитектура", "хаотичн", "clunkier", "messier", "uncomfortable", "glitchy", "scary", "advertising", "horror", "animation", "blinking", "empty", "convenient", "finished", "bad", "burp", "garbage", "design","font","comfort","understandable","useless","architecture","chaotic","страшні", "реклама", "жах", "анімаці", "моргання", "порожні", "зручно", "кінчене", "поган", "ригати", "смітник", "дизайн", "шрифт", "комфорт", "зрозуміл", "марно", "архітектура", "хаотичн"]
    var M7_8b5KeyWords = ["нажима", "выезжа", "экран", "сломан", "меню", "интерфейс", "проигрыватель", "натиска", "виїжджають", "екран", "зламані", "меню", "інтерфейс", "програвач", "push", "drive out", "screen", "broken", "menu", "interface", "player"]
    var M9b5KeyWords = ["украине", "росии", " uk "]
    var M10b5KeyWords = ["сервер", "server", "лежит", "лежат", "вход", "выход", "загру","enter", "input", "output", "download", "exit", "лежить", "лежать", "вхід", "вихід", "завантаж"]
    var M11_12b5KeyWords = ["тормозит", "гальмує", "тупит", "slow", "медлено", "повільно", "shut", "speed", "скорость", "швидкість"]
    var M13b5KeyWords = ["текст", "text", "interface", "интерфейс", "інтерфейс"]
    var M14b5KeyWords = ["озвучка", "sound", "voice", "acting", "дубляж"]
    var M13_14b5KeyWords = ["language", "язык", "мова"]
    var M16b5KeyWords = ["слеп", "глух", "blind", "deaf"]
    var M15_16b5KeyWords = ["поддержк", "бан", "правил", "отключ", "доступ", "блокиру", "цензур", "саппорт", "реагиру", "расизм", "отслежива", "оператор", "ограничени", "политика", "пропаганд", "фашизм", "личная информация", "мораль", "персональные данные", "support", "ban", "rule", "disable", "access", "block", "censorship", "support", "react", "racism", "tracking", "operator", "restrictions"," politic","propaganda","fascism","personal information","moral","personal data", "підтримка", "відключ", "блоку", "реагу", "відслідкову", "обмеж", "політика", "фашизм", "особиста інформація", "персональні дані"]
    
    func getReviewsFromAppStore(numPages: Int, appId: String) {
        reviewsByCategories = [String:[Review]]()
        var page = 1
        var count = 0
        let group = DispatchGroup()
        var helper = 0
        if numPages == 0 {
            helper = 1
        }
        
        for _ in 1...numPages+helper {
            group.enter()
            let url = URL(string: "https://itunes.apple.com/ua/rss/customerreviews/page=" + String(page) + "/id=" + appId + "/sortBy=mostRecent/json")!
            
            let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                guard let data = data else { return }
                if let jsonResult = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String:Any]{
                    self.fullReviews.append(jsonResult)
                    let feed = jsonResult["feed"] as! [String:Any]
                    let entry = feed["entry"] as! [[String:Any]]
                    for x in entry {
                        count += 1
                        let y = x["content"] as! [String:Any]
                        let text = y["label"]! as! String
                        //print(text + "\nm\(count)")
                        let date1 = x["updated"]! as! [String:Any]
                        let date2 = date1["label"] as! String
                        let rating1 = x["im:rating"]! as! [String:Any]
                        let rating2 = rating1["label"] as! String
                        let version1 = x["im:version"]! as! [String:Any]
                        let version2 = version1["label"] as! String
                        let dateFormatter = ISO8601DateFormatter()
                        let date = dateFormatter.date(from:date2)!
                        let review = Review(text.lowercased(),date,Int(rating2)!,version2,appId)
                        self.reviews.append(review)
                    }
                }
                group.leave()
            }
            page += 1
            task.resume()
        }
        group.wait()
    }
    
    func checkAppID(appID: String) -> Bool{
        let group = DispatchGroup()
        var success = false
        group.enter()
        let url = URL(string: "https://itunes.apple.com/ua/rss/customerreviews/page=1/id=" + appID + "/sortBy=mostRecent/json")!
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let data = data else { return }
            if let jsonResult = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String:Any]{
                if let feed = jsonResult["feed"] as? [String:Any]{
                    if (feed["entry"] as? [[String:Any]]) != nil{
                        success = true
                    }
                }
            }
            group.leave()
        }
        task.resume()
        group.wait()
        return success
    }
        
    func sortReviewsByCategories() {
        makeCategoriesInDict()
        keyWordsForCategories(keyWords1: M1b5KeyWords, keyWords2: M2b5KeyWords, keyWords3: M1_2b5KeyWords, metricName: "M1")
        keyWordsForCategories(keyWords1: M3b5KeyWords, keyWords2: M4b5KeyWords, metricName: "M3")
        keyWordsForCategories(keyWords1: M5b5KeyWords, keyWords2: M2b5KeyWords, keyWords3: M5_6b5KeyWords, metricName: "M5")
        keyWordsForCategories(keyWords1: M7b5KeyWords, keyWords2: M8b5KeyWords, keyWords3: M7_8b5KeyWords, metricName: "M7")
        keyWordsForCategories(keyWords1: M9b5KeyWords, keyWords2: M10b5KeyWords, metricName: "M9")
        keyWordsForCategories(keyWords1: M1b5KeyWords, keyWords2: M2b5KeyWords, keyWords3: M11_12b5KeyWords, metricName: "M11")
        keyWordsForCategories(keyWords1: M13b5KeyWords, keyWords2: M14b5KeyWords, keyWords3: M13_14b5KeyWords, metricName: "M13")
        keyWordsForCategories(keyWords1: M9b5KeyWords, keyWords2: M16b5KeyWords, keyWords3: M15_16b5KeyWords, metricName: "M15")
    }
    
    
    func keyWordsForCategories (keyWords1: [String] = [" "], keyWords2: [String] = [" "], keyWords3: [String] = [" "], metricName: String){
        var keyWord1 = false
        var keyWord2 = false
        var keyWord3 = false
        for x in reviews {
            for word in keyWords1 {
                if x.text!.contains(word) {
                    keyWord1 = true
                }
            }
            for word in keyWords2 {
                if x.text!.contains(word) {
                    keyWord2 = true
                }
            }
            for word in keyWords3 {
                if x.text!.contains(word) {
                    keyWord3 = true
                }
            }
            if keyWord1 && keyWord3{
                reviewsByCategories[metricName + "b5"]!.append(x)
            }
            if keyWord2 && keyWord3{
                reviewsByCategories["M" + String(Int.parse(from: metricName)! + 1) + "b5"]!.append(x)
            }
            if keyWord3 && keyWords3 != [" "] {
                if !reviewsByCategories[metricName + "b5"]!.contains(x) && !reviewsByCategories["M" + String(Int.parse(from: metricName)! + 1) + "b5"]!.contains(x) {
                    reviewsByCategories[metricName + "_" + String(Int.parse(from: metricName)! + 1) + "b5"]!.append(x)
                }
            }
            keyWord1 = false
            keyWord2 = false
            keyWord3 = false
        }
    }
    
    func makeCategoriesInDict() {
        for x in 1...16 {
            reviewsByCategories["M" + String(x) + "b5"] = [Review]()
        }
        for x in stride(from: 1, to: 16, by: 2) {
            reviewsByCategories["M" + String(x) + "_" + String(x+1) + "b5"] = [Review]()
        }
    }
    
    func mostPopularWords() {
        var word = ""
        var count = 0
        for x in reviews {
            for ch in x.text! {
                count += 1
                if count == x.text!.count {
                    word.append(ch)
                }
                if (ch != " " && ch != "," && ch != "." && ch != "?" && ch != "!") &&  count != x.text!.count {
                    word.append(ch)
                }
                else if word != ""{
                    if words[word] != nil {
                        words[word]! += 1
                    }
                    else {
                        words[word] = 1
                    }
                    word = ""
                }
            }
            count = 0
        }
        let _ = words.sorted(\.value)
        //print(a)
    }
    
    func filterReviews(date: String = "", version: String = ""){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        var reviewsFiltered = [Review]()
        for review in reviews {
            if date != "" && version != "" {
                if dateFormatter.string(from: review.date!) == date && review.version == version {
                    reviewsFiltered.append(review)
                }
            }
            else if date != "" {
                if dateFormatter.string(from: review.date!) == date {
                    reviewsFiltered.append(review)
                }
            }
            else if version != "" {
                if review.version == version{
                    reviewsFiltered.append(review)
                }
            }
        }
        reviews = reviewsFiltered
    }
    
    func checkDate(date: String = "") -> Bool{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        for review in reviews {
            if dateFormatter.string(from: review.date!) == date {
                return true
            }
        }
        return false
    }
    
    func checkVersion(version: String = "") -> Bool{
        for review in reviews {
            if review.version == version {
                return true
            }
        }
        return false
    }
    
    func createReviews(){
        for x in reviews{
            if !findReview(review: x){
                try! realm.write {
                    let review = RealmReview()
                    review.text = x.text!
                    review.appID = x.appID!
                    review.version = x.version!
                    review.date = x.date!
                    review.rating = x.rating!
                    realm.add(review)
                }
            }
        }
    }
    
    func findReview(review: Review) -> Bool {
        let findReview = realmReviews.where {
            $0.text == review.text!
        }
        if findReview.isEmpty == false {
            return true
        }
        else {
            return false
        }
    }
    
    func findReviews(appID: String){
        let findReviews = realmReviews.where {
            $0.appID == appID
        }
        if findReviews.isEmpty == false {
            for review in findReviews {
                currentReviews.append(review)
            }
            for x in currentReviews{
                reviews.append(Review(x.text, x.date, x.rating, x.version, x.appID))
            }
        }
    }
    
    func checkAppIDDatabase(appID: String) -> Bool{
        let findReviews = realmReviews.where {
            $0.appID == appID
        }
        if findReviews.isEmpty == false {
            return true
        }
        else {
            return false
        }
        
    }
    
    func reviewsCoundDB(appID: String) -> Int{
        let findReviews = realmReviews.where {
            $0.appID == appID
        }
        if findReviews.isEmpty == false {
            return findReviews.count
        }
        else {
            return 0
        }
    }
    
    func deleteAll() {
        try! realm.write {
            realm.delete(realmReviews)
        }
    }
        
}

extension Sequence {
    func sorted<T: Comparable>(_ predicate: (Element) -> T, by areInIncreasingOrder: ((T,T)-> Bool) = (<)) -> [Element] {
        sorted(by: { areInIncreasingOrder(predicate($0), predicate($1)) })
    }
}

extension Int {
    static func parse(from string: String) -> Int? {
        return Int(string.components(separatedBy: CharacterSet.decimalDigits.inverted).joined())
    }
}

