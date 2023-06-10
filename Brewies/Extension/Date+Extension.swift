//
//  Date+Extension.swift
//  Brewies
//
//  Created by Noah Boyers on 5/29/23.
//

import Foundation

extension Date {
    static func fromString(_ string: String, date: Date) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HHmm"
        guard let time = formatter.date(from: string) else {
            return nil
        }
        
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        var timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        timeComponents.year = dateComponents.year
        timeComponents.month = dateComponents.month
        timeComponents.day = dateComponents.day
        
        return calendar.date(from: timeComponents)
    }
    
    static func fromTime(_ time: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HHmm"
        return formatter.date(from: time)
    }
    
    
    
    static func startOfDay(of date: Date) -> Date {
        return Calendar.current.startOfDay(for: date)
    }
    
    static func endOfDay(of date: Date) -> Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay(of: date))!
    }
}
