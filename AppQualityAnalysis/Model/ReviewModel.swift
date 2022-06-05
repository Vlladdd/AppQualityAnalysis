//
//  ReviewModel.swift
//  AppQualityAnalysis
//
//  Created by Vlad Nechyporenko on 02.11.2021.
//

import Foundation
import RealmSwift

//MARK: - Review Blank

//struct that represents copy of Review object in Realm
struct ReviewBlank: Equatable{

    var text: String
    var date: Date
    var rating: Int
    var version: String
    var appID: String
    
    init(text: String, date: Date, rating: Int, version: String, appID: String){
        self.text = text
        self.date = date
        self.rating = rating
        self.version = version
        self.appID = appID
    }
    
    static func == (lhs: ReviewBlank, rhs: ReviewBlank) -> Bool {
        lhs.text == rhs.text
    }
    
}

//MARK: - Review

//class that represents Review object in Realm
class Review: Object {
    @Persisted var text: String
    @Persisted var date: Date
    @Persisted var rating: Int
    @Persisted var version: String
    @Persisted var appID: String
}

//MARK: - Category

//class that represents Category
//used to make code more simple and readable
private struct Category {
    
    let name: String
    let keywords: [String]
    
    init(name: String, keywords: [String]){
        self.name = name
        self.keywords = keywords
    }
    
}

//MARK: - Model of Review

//class that represents model of Review
class ReviewModel {
    
    //MARK: - Properties
    
    var reviews = [ReviewBlank]()
    var reviewsByCategories = [String:[ReviewBlank]]()
    
    //MARK: - Functions
    
    //gets *count*(100) reviews from AppStore
    func getReviewsFromAppStore(count: Int, appId: String, completion: @escaping (OriginOfData) -> ()) {
        reviewsByCategories = [String:[ReviewBlank]]()
        var numberOfPages = count / ReviewModelConstants.reviewPerPageInAppStore
        var isError = false
        var errorMessage = ""
        var completedPages = 0
        if numberOfPages == 0 {
            numberOfPages = 1
        }
        let reviewsOnPages = ReviewModelConstants.reviewPerPageInAppStore * numberOfPages
        //there could be more reviews than we need
        let reviewsToDrop = reviewsOnPages - count
        for currentPage in 1...numberOfPages {
            let url = URL(string: "https://itunes.apple.com/ua/rss/customerreviews/page=" + String(currentPage) + "/id=" + appId + "/sortBy=mostRecent/json")!
            let task = URLSession.shared.dataTask(with: url) {[weak self] data, response, error in
                if !isError, let error = error {
                    isError = true
                    errorMessage = error.localizedDescription
                }
                else if let data = data, let jsonResult = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String:Any]{
                    if let feed = jsonResult["feed"] as? [String:Any], let entry = feed["entry"] as? [[String:Any]]{
                        for value in entry {
                            if let content = value["content"] as? [String:Any], let text = content["label"]! as? String{
                                if let updated = value["updated"]! as? [String:Any], let dateValue = updated["label"] as? String{
                                    if let imRating = value["im:rating"]! as? [String:Any], let rating = imRating["label"] as? String{
                                        if let imVersion = value["im:version"]! as? [String:Any], let version = imVersion["label"] as? String{
                                            let dateFormatter = ISO8601DateFormatter()
                                            let date = dateFormatter.date(from:dateValue)
                                            if let date = date, let rating = Int(rating){
                                                let review = ReviewBlank(text: text.lowercased(),date: date,rating: rating,version: version,appID: appId)
                                                if let self = self {
                                                    if !self.reviews.contains(review){
                                                        self.reviews.append(review)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    else {
                        isError = true
                        errorMessage = "Wrong AppID or not enough reviews!"
                    }
                }
                else {
                    isError = true
                    errorMessage = "No data!"
                }
                completedPages += 1
                if completedPages == numberOfPages {
                    if let self = self {
                        if isError {
                            completion(.failure(errorMessage))
                        }
                        else {
                            self.saveReviews()
                            self.reviews = self.reviews.dropLast(reviewsToDrop)
                            self.sortReviewsByCategories()
                            completion(.appStore)
                        }
                    }
                }
            }
            task.resume()
        }
    }
        
    //sorts reviews by categories by using keywords
    private func sortReviewsByCategories() {
        makeEmptyReviewsByCategories()
        for category in ReviewModelConstants.categories {
            let subCategory1 = category.count == 2 ? category[0] : nil
            let subCategory2 = category.count == 2 ? category[1] : nil
            let subCategory3 = category.count == 3 ? category[2] : nil
            sortReviews(category1: subCategory1, category2: subCategory2, category3: subCategory3)
        }
    }
    
    private func sortReviews(category1: Category?, category2: Category?, category3: Category?){
        var keyWord1 = false
        var keyWord2 = false
        var keyWord3 = false
        for review in reviews {
            if let category1 = category1 {
                for word in category1.keywords {
                    if review.text.contains(word) {
                        keyWord1 = true
                    }
                }
            }
            if let category2 = category2 {
                for word in category2.keywords {
                    if review.text.contains(word) {
                        keyWord2 = true
                    }
                }
            }
            if let category3 = category3 {
                for word in category3.keywords {
                    if review.text.contains(word) {
                        keyWord3 = true
                    }
                }
            }
            if (keyWord1 && keyWord3 && category3 != nil && category1 != nil) || keyWord1 && category1 != nil{
                reviewsByCategories[category1!.name]?.append(review)
            }
            if (keyWord2 && keyWord3 && category3 != nil && category2 != nil) || keyWord2 && category2 != nil{
                reviewsByCategories[category2!.name]?.append(review)
            }
            if keyWord3 && category3 != nil && category2 != nil && category1 != nil{
                if let reviews1 = reviewsByCategories[category1!.name], let reviews2 = reviewsByCategories[category2!.name] {
                    if !reviews1.contains(review) && !reviews2.contains(review) {
                        reviewsByCategories[category3!.name]?.append(review)
                    }
                }
            }
            keyWord1 = false
            keyWord2 = false
            keyWord3 = false
        }
    }
    
    private func makeEmptyReviewsByCategories() {
        for category in ReviewModelConstants.categories {
            for subcategory in category {
                reviewsByCategories[subcategory.name] = [ReviewBlank]()
            }
        }
    }
    
    //filters reviews by date and version
    func filterReviews(date: String = "", version: String = ""){
        var reviewsFiltered = [ReviewBlank]()
        for review in reviews {
            if !date.isEmpty && !version.isEmpty {
                if ReviewModelConstants.dateFormatter.string(from: review.date) == date && review.version == version {
                    reviewsFiltered.append(review)
                }
            }
            else if !date.isEmpty {
                if ReviewModelConstants.dateFormatter.string(from: review.date) == date {
                    reviewsFiltered.append(review)
                }
            }
            else if !version.isEmpty {
                if review.version == version{
                    reviewsFiltered.append(review)
                }
            }
        }
        reviews = reviewsFiltered
        sortReviewsByCategories()
    }
    
    //checks if review with certain date exists
    func checkDate(date: String) -> Bool{
        for review in reviews {
            if ReviewModelConstants.dateFormatter.string(from: review.date) == date {
                return true
            }
        }
        return false
    }
    
    //checks if review with certain version exists
    func checkVersion(version: String) -> Bool{
        for review in reviews {
            if review.version == version {
                return true
            }
        }
        return false
    }
    
    //saves reviews to Realm
    private func saveReviews(){
        let realm = try! Realm()
        for review in reviews {
            let realmReview = Review()
            realmReview.text = review.text
            realmReview.date = review.date
            realmReview.rating = review.rating
            realmReview.version = review.version
            realmReview.appID = review.appID
            if !findReview(review: realmReview){
                try! realm.write {
                    realm.add(realmReview)
                }
            }
        }
    }
    
    //checks if review already exists in Realm
    private func findReview(review: Review) -> Bool {
        let realm = try! Realm()
        let reviews = realm.objects(Review.self)
        let findReviews = reviews.where {
            $0.text == review.text
        }
        if findReviews.isEmpty == false {
            return true
        }
        else {
            return false
        }
    }
    
    //gets reviews about app with appID from Realm
    func findReviews(appID: String){
        let realm = try! Realm()
        let reviews = realm.objects(Review.self)
        let findReviews = reviews.where {
            $0.appID == appID
        }
        if findReviews.isEmpty == false {
            for review in findReviews {
                let reviewBlank = ReviewBlank(text: review.text, date: review.date, rating: review.rating, version: review.version, appID: review.appID)
                if !self.reviews.contains(reviewBlank){
                    self.reviews.append(reviewBlank)
                }
            }
            sortReviewsByCategories()
        }
    }
    
    //checks if reviews about app with appID exists in Realm
    func checkAppIDinDatabase(appID: String) -> Bool{
        let realm = try! Realm()
        let reviews = realm.objects(Review.self)
        let findReviews = reviews.where {
            $0.appID == appID
        }
        if findReviews.isEmpty == false {
            return true
        }
        else {
            return false
        }
        
    }
    
    //gets total count of reviews about app with appID in Realm
    func reviewsCountInDB(appID: String) -> Int{
        let realm = try! Realm()
        let reviews = realm.objects(Review.self)
        let findReviews = reviews.where {
            $0.appID == appID
        }
        return findReviews.count
    }
        
}

//MARK: - Constants

private struct ReviewModelConstants {
    
    static let dateFormat = "dd/MM/yyyy"
    static var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        return dateFormatter
    }
    static let reviewPerPageInAppStore = 50
    static let M1b5KeyWords = ["ios", "операционая система", "операційна система", " ос ", "operation system", " os "]
    static let M2b5KeyWords = ["device", "пристрій", "iphone", "ipad", "устройство", "смартфон", "телефон", "планшет", "мобильный"]
    static let M1_2b5KeyWords = ["выбрасыва", "правильн", "работа", "существу", "подтягива", "мог", "выбива", "ошибк", "лаг", "баг", "викида", "працю", "існу", "підтяг", "міг", "вибива", "помилк", "змоги", "можу", "throw", "correct", "work", "exist", "get", "can", "exit", "error", "lag", "bug", "correct"]
    static let M4b5KeyWords = ["привязаны", "другие приложения", "tied", "other apps", "прив'язані", "інші застосунки", "через фейсбук", "via"]
    static let M3b5KeyWords = ["открыва", "удали", "вход", "убрать", "скача", "настрои", "зайти", "приход", "пропал", "доступ", "видно", "выход", "войти", "выйти", "загруз", "обновить", "зайти", "уведомления", "open", "delete", "enter", "remove", "download", "configure", "disappeared", "access", "visible", "exit", "update", "notifications", "відкрива", "видал", "вхід", "прибрати", "налашту", "пропав", "вихід", "увійти", "вийти", "завантаж", "оновити", "повідомлення"]
    static let M5b5KeyWords = ["горизонта", "вертикаль", "дисплей", "ориентация","horizontal", "vertical", "display", "orientation", "орієнтація", "экран", "екран", "screen"]
    static let M5_6b5KeyWords = ["меняется", "размер интерфейс", "элементы","змінюється", "розмір інтерфейс", "елементи", "changes", "interface size"]
    static let M7b5KeyWords = ["правильн", "належн", "correct"]
    static let M8b5KeyWords = ["страшн", "реклама", "ужас", "анимаци", "морга", "пуст", "удобн", "кончен", "плохо", "рыгать", "помойка", "дизайн", "шрифт", "комфорт", "понятн", "бесполезн", "архитектура", "хаотичн", "clunkier", "messier", "uncomfortable", "glitchy", "scary", "advertising", "horror", "animation", "blinking", "empty", "convenient", "finished", "bad", "burp", "garbage", "design","font","comfort","understandable","useless","architecture","chaotic","страшні", "реклама", "жах", "анімаці", "моргання", "порожні", "зручно", "кінчене", "поган", "ригати", "смітник", "дизайн", "шрифт", "комфорт", "зрозуміл", "марно", "архітектура", "хаотичн"]
    static let M7_8b5KeyWords = ["нажима", "выезжа", "экран", "сломан", "меню", "интерфейс", "проигрыватель", "натиска", "виїжджають", "екран", "зламані", "меню", "інтерфейс", "програвач", "push", "drive out", "screen", "broken", "menu", "interface", "player"]
    static let M9b5KeyWords = ["украине", "росии", " uk "]
    static let M10b5KeyWords = ["сервер", "server", "лежит", "лежат", "вход", "выход", "загру","enter", "input", "output", "download", "exit", "лежить", "лежать", "вхід", "вихід", "завантаж"]
    static let M11_12b5KeyWords = ["тормозит", "гальмує", "тупит", "slow", "медлено", "повільно", "shut", "speed", "скорость", "швидкість"]
    static let M13b5KeyWords = ["текст", "text", "interface", "интерфейс", "інтерфейс"]
    static let M14b5KeyWords = ["озвучка", "sound", "voice", "acting", "дубляж"]
    static let M13_14b5KeyWords = ["language", "язык", "мова"]
    static let M16b5KeyWords = ["слеп", "глух", "blind", "deaf"]
    static let M15_16b5KeyWords = ["поддержк", "бан", "правил", "отключ", "доступ", "блокиру", "цензур", "саппорт", "реагиру", "расизм", "отслежива", "оператор", "ограничени", "политика", "пропаганд", "фашизм", "личная информация", "мораль", "персональные данные", "support", "ban", "rule", "disable", "access", "block", "censorship", "support", "react", "racism", "tracking", "operator", "restrictions"," politic","propaganda","fascism","personal information","moral","personal data", "підтримка", "відключ", "блоку", "реагу", "відслідкову", "обмеж", "політика", "фашизм", "особиста інформація", "персональні дані"]
    static let M1_2values = [Category(name: "M1b5", keywords: M1b5KeyWords), Category(name: "M2b5", keywords: M2b5KeyWords), Category(name: "M1_2b5", keywords: M1_2b5KeyWords)]
    static let M3_4values = [Category(name: "M3b5", keywords: M3b5KeyWords), Category(name: "M4b5", keywords: M4b5KeyWords)]
    static let M5_6values = [Category(name: "M5b5", keywords: M5b5KeyWords), Category(name: "M6b5", keywords: M2b5KeyWords), Category(name: "M5_6b5", keywords: M5_6b5KeyWords)]
    static let M7_8values = [Category(name: "M7b5", keywords: M7b5KeyWords), Category(name: "M8b5", keywords: M8b5KeyWords), Category(name: "M7_8b5", keywords: M7_8b5KeyWords)]
    static let M9_10values = [Category(name: "M9b5", keywords: M9b5KeyWords), Category(name: "M10b5", keywords: M10b5KeyWords)]
    static let M11_12values = [Category(name: "M11b5", keywords: M1b5KeyWords), Category(name: "M12b5", keywords: M2b5KeyWords), Category(name: "M11_12b5", keywords: M11_12b5KeyWords)]
    static let M13_14values = [Category(name: "M13b5", keywords: M13b5KeyWords), Category(name: "M14b5", keywords: M14b5KeyWords), Category(name: "M13_14b5", keywords: M13_14b5KeyWords)]
    static let M15_16values = [Category(name: "M15b5", keywords: M9b5KeyWords), Category(name: "M16b5", keywords: M16b5KeyWords), Category(name: "M15_16b5", keywords: M15_16b5KeyWords)]
    static let categories = [M1_2values, M3_4values, M5_6values, M7_8values, M9_10values, M11_12values, M13_14values, M15_16values]
    
}
