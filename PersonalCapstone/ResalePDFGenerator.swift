//
//  ResalePDFGenerator.swift
//  PersonalCapstone
//
//  Created by Emilio Briceno on 9/1/26.
//


import UIKit

enum ResalePDFGenerator {

    static func generate(for vehicle: Vehicle) -> Data {
        let pageWidth: CGFloat = 612   // US Letter, 72pt/inch
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 40
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let records = (vehicle.serviceRecords as? Set<ServiceRecord> ?? [])
            .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }

        let titleFont = UIFont.boldSystemFont(ofSize: 20)
        let subtitleFont = UIFont.systemFont(ofSize: 12)
        let headerFont = UIFont.boldSystemFont(ofSize: 11)
        let rowFont = UIFont.systemFont(ofSize: 10)
        let footerFont = UIFont.systemFont(ofSize: 8)

        // Column x-positions: Date | Mileage | Type | Shop | Cost
        let colDate = margin
        let colMileage = margin + 85
        let colType = margin + 155
        let colShop = margin + 320
        let colCost = pageWidth - margin - 60

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let data = renderer.pdfData { context in
            var y: CGFloat = margin

            func drawTableHeader() {
                let headers: [(String, CGFloat)] = [
                    ("Date", colDate), ("Mileage", colMileage), ("Type", colType),
                    ("Shop", colShop), ("Cost", colCost)
                ]
                for (text, x) in headers {
                    text.draw(at: CGPoint(x: x, y: y), withAttributes: [.font: headerFont])
                }
                y += 16
                let line = UIBezierPath()
                line.move(to: CGPoint(x: margin, y: y))
                line.addLine(to: CGPoint(x: pageWidth - margin, y: y))
                UIColor.gray.setStroke()
                line.lineWidth = 0.5
                line.stroke()
                y += 8
            }

            func startPage() {
                context.beginPage()
                y = margin
            }

            startPage()

            // Header
            let title = "\(String(vehicle.year)) \(vehicle.make ?? "") \(vehicle.model ?? "")"
            title.draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: titleFont])
            y += 28

            var subtitleParts: [String] = []
            if let vin = vehicle.vin, !vin.isEmpty { subtitleParts.append("VIN: \(vin)") }
            if let plate = vehicle.licensePlate, !plate.isEmpty { subtitleParts.append("Plate: \(plate)") }
            subtitleParts.append("Current Odometer: \(vehicle.odometer) mi")
            subtitleParts.joined(separator: "   ·   ").draw(
                at: CGPoint(x: margin, y: y),
                withAttributes: [.font: subtitleFont, .foregroundColor: UIColor.darkGray]
            )
            y += 20

            let totalSpent = records.reduce(0.0) { $0 + $1.cost }
            let summary = "\(records.count) service record\(records.count == 1 ? "" : "s")   ·   Total spent: \(totalSpent.formatted(.currency(code: "USD")))"
            summary.draw(
                at: CGPoint(x: margin, y: y),
                withAttributes: [.font: subtitleFont, .foregroundColor: UIColor.darkGray]
            )
            y += 26

            if records.isEmpty {
                "No service records yet.".draw(
                    at: CGPoint(x: margin, y: y),
                    withAttributes: [.font: rowFont, .foregroundColor: UIColor.gray]
                )
            } else {
                drawTableHeader()

                for record in records {
                    if y > pageHeight - margin - 30 {
                        startPage()
                        drawTableHeader()
                    }

                    let dateStr = record.date.map { dateFormatter.string(from: $0) } ?? "—"
                    dateStr.draw(at: CGPoint(x: colDate, y: y), withAttributes: [.font: rowFont])

                    "\(record.mileage) mi".draw(at: CGPoint(x: colMileage, y: y), withAttributes: [.font: rowFont])

                    (record.type ?? "—").draw(
                        in: CGRect(x: colType, y: y, width: colShop - colType - 8, height: 14),
                        withAttributes: [.font: rowFont]
                    )

                    (record.shop ?? "—").draw(
                        in: CGRect(x: colShop, y: y, width: colCost - colShop - 8, height: 14),
                        withAttributes: [.font: rowFont]
                    )

                    record.cost.formatted(.currency(code: "USD")).draw(
                        at: CGPoint(x: colCost, y: y),
                        withAttributes: [.font: rowFont]
                    )

                    y += 18
                }
            }

            // Footer on the last page
            let footerY = pageHeight - margin - 12
            let footer = "Generated by PersonalCapstone on \(Date().formatted(date: .abbreviated, time: .omitted))"
            footer.draw(at: CGPoint(x: margin, y: footerY), withAttributes: [.font: footerFont, .foregroundColor: UIColor.gray])
        }

        return data
    }
}
