//
//  ImageModifer.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/10/18.
//  Copyright © 2018 season. All rights reserved.
//

import Foundation

protocol ImageModifier {
    
    func modify(_ image: Image) -> Image
}

extension ImageModifier {
    func modify(_ image: Image?) -> Image? {
        guard let image = image else { return nil }
        
        return modify(image)
    }
}

typealias ModiferImp = ((Image) -> Image)

fileprivate struct GeneralModifier: ImageModifier {
    let identifier: String
    let m: ModiferImp
    
    func modify(_ image: Image) -> Image {
        return m(image)
    }
}
