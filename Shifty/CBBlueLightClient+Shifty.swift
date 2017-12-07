//
//  CBBlueLightClient+Shifty.swift
//  Shifty
//
//  Created by Nate Thompson on 7/14/17.
//
//

import Foundation

enum ScheduleType {
    case off
    case sunSchedule
    case timedSchedule(startTime: Date, endTime: Date)
}

extension CBBlueLightClient {
    static let shared = CBBlueLightClient(notificationBlock: BLNotificationBlock)
    
    private convenience init(notificationBlock: (@convention(block) () -> Void)) {
        self.init()
        setStatusNotificationBlock(notificationBlock)
    }

    var blueLightStatus: StatusData {
        var statusData: StatusData = StatusData()
        getBlueLightStatus(&statusData)
        return statusData
    }
    
    var strength: Float {
        var strength: Float = 0.0
        self.getStrength(&strength)
        return strength
    }
    
    var CCT: Float {
        var CCT: Float = 0.0
        self.getCCT(&CCT)
        return CCT
    }
    
    var isNightShiftEnabled: Bool {
        return blueLightStatus.enabled.boolValue
    }
    
    var schedule: ScheduleType {
        switch blueLightStatus.mode {
        case 0:
            return .off
        case 1:
            return .sunSchedule
        case 2:
            let calendar = NSCalendar(identifier: .gregorian)!
            let now = Date()
            var startComponents = calendar.components([.year, .month, .day, .hour, .minute, .second], from: now)
            var endComponents = calendar.components([.year, .month, .day, .hour, .minute, .second], from: now)
            
            startComponents.hour = Int(blueLightStatus.schedule.fromTime.hour)
            startComponents.minute = Int(blueLightStatus.schedule.fromTime.minute)
            startComponents.second = 0
            var startDate = calendar.date(from: startComponents)
            
            endComponents.hour = Int(blueLightStatus.schedule.toTime.hour)
            endComponents.minute = Int(blueLightStatus.schedule.toTime.minute)
            endComponents.second = 0
            var endDate = calendar.date(from: endComponents)
            
            if let startDay = startComponents.day,
                let endDay = endComponents.day,
                let start = startDate,
                let end = endDate {
                
                //If start and end times are on different days, adjust relative date based on current time
                if start > end {
                    if now > start {
                        endComponents.day = endDay + 1
                        endDate = calendar.date(from: endComponents)
                    } else if now < end {
                        startComponents.day = startDay - 1
                        startDate = calendar.date(from: startComponents)
                    }
                }
            }
            
            if let startDate = startDate, let endDate = endDate {
                return .timedSchedule(startTime: startDate, endTime: endDate)
            } else {
                return .off
            }
            
        default:
            return .off
        }
    }
    
    func setSchedule(_ schedule: ScheduleType) {
        switch schedule {
        case .off:
            setMode(0)
        case .sunSchedule:
            setMode(1)
        case .timedSchedule(startTime: let startTime, endTime: let endTime):
            setMode(2)
            
            let calendar = NSCalendar(identifier: .gregorian)!
            let startComponents = calendar.components([.year, .month, .day, .hour, .minute, .second], from: startTime)
            let fromTime = Time(hour: Int32(startComponents.hour!), minute: Int32(startComponents.minute!))

            let endComponents = calendar.components([.year, .month, .day, .hour, .minute, .second], from: endTime)
            let toTime = Time(hour: Int32(endComponents.hour!), minute: Int32(endComponents.minute!))
            
            var schedule = Schedule(fromTime: fromTime, toTime: toTime)
            setSchedule(&schedule)
        }
    }
    
    var isOffSchedule: Bool {
        switch schedule {
        case .off: return true
        default: return false
        }
    }
    
    var isSunSchedule: Bool {
        switch schedule {
        case .sunSchedule: return true
        default: return false
        }
    }
    
    var isTimedSchedule: Bool {
        switch schedule {
        case .timedSchedule(_,_): return true
        default: return false
        }
    }
}


