//
//  ScheduledTaskStatus.swift
//  PersonalCapstone
//
//  Created by Emilio Briceno on 8/20/26.
//

import SwiftUI

extension ScheduledTask {
    var statusColor: Color {
        switch status {
        case "Due Soon": return .red
        case "Scheduled": return .green
        default: return .orange //"Upcoming" and any unrecognized value
        }
    }
}
