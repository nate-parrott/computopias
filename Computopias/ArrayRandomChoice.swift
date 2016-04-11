//
//  ArrayRandomChoice.swift
//  Computopias
//
//  Created by Nate Parrott on 4/11/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation

extension Array {
    func randomChoice() -> Element! {
        if count > 0 {
            return self[Int(random()) % count]
        } else {
            return nil
        }
    }
}
