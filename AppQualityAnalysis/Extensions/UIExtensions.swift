//
//  UIExtensions.swift
//  AppQualityAnalysis
//
//  Created by Vlad Nechyporenko on 28.05.2022.
//

import UIKit

//MARK: - Some useful UI extensions

extension UIStackView {

    func removeFullyAllArrangedSubviews() {
        arrangedSubviews.forEach { view in
            removeFully(view: view)
        }
    }
    
    private func removeFully(view: UIView) {
        removeArrangedSubview(view)
        view.removeFromSuperview()
    }

}

extension UIViewController {
    
    func makeSpinner() -> UIActivityIndicatorView{
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.center = CGPoint(x: view.frame.midX, y: view.frame.midY)
        spinner.autoresizingMask = [.flexibleBottomMargin, .flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin]
        spinner.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .black : .white
        spinner.startAnimating()
        return spinner
    }
    
}
