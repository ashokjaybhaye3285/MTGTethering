//
//  Delimiters.swift
//  YukonSim
//
//  Created by Schumacher Clay on 4/11/16.
//  Copyright © 2016 Deere & Company. All rights reserved.
//

import Foundation

// delimiter at the end of the message
let EOM_DELIMITER = "\u{1C}"
// delimiter for sets of fields
let RECORD_DELIMITER = "\u{1E}"
// delimiter for each field in the message
let UNIT_DELIMITER = "\u{1F}"

let EOM_DELIMITER_BYTE: UInt8 = 28;